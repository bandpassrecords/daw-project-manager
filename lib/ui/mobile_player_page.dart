import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/audio_analysis_service.dart';
import '../utils/mobile_utils.dart';
import '../utils/playback_seek.dart';
import '../utils/project_freshness.dart';
import 'preview_share.dart';
import 'project_detail_page.dart';
import 'widgets/conversion_progress_dialog.dart';
import 'widgets/project_notes_section.dart';
import 'widgets/waveform_widget.dart';

/// Route for the full mobile player. On Android it slides up from the bottom
/// on push and back down on pop (the "now playing" sheet gesture) instead of
/// the platform default zoom/fade; other platforms keep their native page
/// transition.
Route<void> mobilePlayerPageRoute() =>
    buildMobilePlayerRoute(android: MobileUtils.isAndroid());

@visibleForTesting
Route<void> buildMobilePlayerRoute({required bool android}) {
  if (!android) {
    return MaterialPageRoute(builder: (_) => const MobilePlayerPage());
  }
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const MobilePlayerPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
  );
}

class MobilePlayerPage extends ConsumerStatefulWidget {
  const MobilePlayerPage({super.key});

  @override
  ConsumerState<MobilePlayerPage> createState() => _MobilePlayerPageState();
}

class _MobilePlayerPageState extends ConsumerState<MobilePlayerPage> {
  late PageController _pageController;
  bool _suppressPageChange = false;

  // Mono state (local to the player page, per-project)
  bool _isMono = false;
  bool _isGeneratingMono = false;
  // mono file path cache: projectId → monoFilePath
  final Map<String, String> _monoCache = {};

  @override
  void initState() {
    super.initState();
    final idx = ref.read(mobilePlayerProvider).queueIndex;
    _pageController = PageController(initialPage: idx, viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageToState(int idx) {
    if (!_pageController.hasClients) return;
    if ((_pageController.page?.round() ?? idx) == idx) return;
    _suppressPageChange = true;
    _pageController
        .animateToPage(idx,
            duration: const Duration(milliseconds: 280), curve: Curves.easeInOut)
        .then((_) => _suppressPageChange = false);
  }

  Future<void> _onPageChanged(int newPage, List<MusicProject> queue) async {
    if (_suppressPageChange) return;
    if (newPage < 0 || newPage >= queue.length) return;
    final notifier = ref.read(mobilePlayerProvider.notifier);
    // The mono swap is per-track and survives a swipe away and back, so show
    // the toggle in whatever state the player actually holds for this track.
    setState(() {
      _isMono = notifier.hasSourceOverrideFor(queue[newPage].id);
    });
    final stateQueue = ref.read(mobilePlayerProvider).queue;
    if (stateQueue.isEmpty) {
      // Player not initialised via playProject yet — start it from this queue.
      final project = queue[newPage];
      final path = project.previewSongPath?.isNotEmpty == true
          ? project.previewSongPath!
          : project.previewSongAutoPath;
      if (path == null) return;
      await notifier.playProject(project, path,
          queue: queue, queueIndex: newPage);
    } else {
      // `queue` is already the ordered play sequence — just jump to the page so
      // the swipe follows shuffle order instead of the sequential neighbour.
      await notifier.playAtIndex(newPage);
    }
  }

  /// Opens a bottom sheet to add a todo to the currently-playing project,
  /// capturing the current playback position so the entry is tagged with the
  /// exact `[m:ss]` where it was created.
  Future<void> _openAddTodoSheet() async {
    final playerState = ref.read(mobilePlayerProvider);
    final project = playerState.currentProject;
    if (project == null) return;
    final position = playerState.position;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addTaskAtTimestamp,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(formatDuration(position),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(project.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.taskDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (text == null || text.trim().isEmpty) return;
    await _addTodoAtTimestamp(project, position, text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.taskAdded)));
  }

  Future<void> _addTodoAtTimestamp(
      MusicProject project, Duration position, String text) async {
    final repo = await ref.read(repositoryProvider.future);
    // Use the freshest copy of the project so we don't clobber edits made
    // elsewhere while the track was playing.
    var latest = project;
    final list = ref.read(allProjectsStreamProvider).asData?.value;
    if (list != null) {
      for (final pr in list) {
        if (pr.id == project.id) {
          latest = pr;
          break;
        }
      }
    }
    final newTodo = TodoItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      text: buildTimestampedTodoText(position, text),
      createdAt: DateTime.now(),
    );
    await repo.updateProject(
        latest.copyWith(todos: [...latest.todos, newTodo]));
    ref.invalidate(allProjectsStreamProvider);
  }

  bool _supportsMonoMix(String? path) {
    if (path == null || path.isEmpty) return false;
    final ext = path.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'}.contains(ext);
  }

  void _showQueueSheet(
      BuildContext context, List<MusicProject> queue, int currentIdx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => _QueueSheet(
          queue: queue,
          currentIdx: currentIdx,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  Future<void> _sharePreviewSong() async {
    final project = ref.read(mobilePlayerProvider).currentProject;
    final songPath = ref.read(mobilePlayerProvider).effectivePath;
    if (project == null || songPath == null) return;
    if (songPath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }
    try {
      final sourceFile = File(songPath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }
      String originalFileName = project.previewShareFileName ?? p.basename(songPath);
      if (!originalFileName.contains('.')) {
        originalFileName = '$originalFileName${p.extension(songPath)}';
      }

      // WhatsApp (confirmed via manual testing) rejects WAV/AIFF/FLAC as a
      // direct audio attachment with no error shown to us — convert to a
      // compatible format first so the shared file is actually accepted.
      var fileToShare = sourceFile;
      var shareFileName = originalFileName;
      if (AudioAnalysisService.needsConversionForSharing(songPath) && mounted) {
        final converted = await convertForSharingWithProgress(context, songPath);
        if (converted != null) {
          fileToShare = converted;
          shareFileName = p.basename(converted.path);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mp3ConversionFailed)),
          );
        }
      }

      final shareFile = await stageFileForMobileShare(fileToShare, shareFileName);
      if (shareFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToSharePreviewSong(shareFileName),
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile(
            shareFile.path,
            name: shareFileName,
            mimeType: shareMimeTypeForFileName(shareFileName),
          ),
        ],
        text: AppLocalizations.of(context)!.sharePreviewSongText(project.displayName),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSong(e.toString()))),
        );
      }
    }
  }

  Future<void> _sharePreviewSongAsZip() async {
    final project = ref.read(mobilePlayerProvider).currentProject;
    final songPath = ref.read(mobilePlayerProvider).effectivePath;
    if (project == null || songPath == null) return;
    if (songPath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }
    try {
      final sourceFile = File(songPath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }
      String originalFileName = project.previewShareFileName ?? p.basename(songPath);
      if (!originalFileName.contains('.')) {
        originalFileName = '$originalFileName${p.extension(songPath)}';
      }
      final cacheDir = await getTemporaryDirectory();
      final shareFile = await stageFileForMobileShare(sourceFile, originalFileName);
      if (shareFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToSharePreviewSongAsZip(originalFileName),
              ),
            ),
          );
        }
        return;
      }

      final zipBase = p.basenameWithoutExtension(originalFileName);
      var zipPath = p.join(cacheDir.path, '$zipBase.zip');
      var zipFile = File(zipPath);
      if (await zipFile.exists()) {
        zipPath = p.join(cacheDir.path, '${zipBase}_${DateTime.now().millisecondsSinceEpoch}.zip');
        zipFile = File(zipPath);
      }
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      await encoder.addFile(shareFile);
      encoder.close();

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(zipFile.path, name: p.basename(zipFile.path), mimeType: 'application/zip')],
        text: AppLocalizations.of(context)!.sharePreviewSongZipText(project.displayName),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSongAsZip(e.toString()))),
        );
      }
    }
  }

  /// Jump [seconds] (±) from the current position, clamped to the track.
  void _seekBy(int seconds) {
    final s = ref.read(mobilePlayerProvider);
    ref
        .read(mobilePlayerProvider.notifier)
        .seek(seekTarget(s.position, seconds, s.duration));
  }

  Future<void> _toggleMono() async {
    final state = ref.read(mobilePlayerProvider);
    final project = state.currentProject;
    if (project == null) return;

    final stereoPath = project.previewSongPath?.isNotEmpty == true
        ? project.previewSongPath!
        : project.previewSongAutoPath;
    if (stereoPath == null) return;

    if (!_supportsMonoMix(stereoPath)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.monoRequiresWav)),
        );
      }
      return;
    }

    final newMono = !_isMono;
    final savedPosition = state.position;

    if (newMono) {
      String? monoPath = _monoCache[project.id];
      if (monoPath == null) {
        setState(() => _isGeneratingMono = true);
        final tmpDir = await getTemporaryDirectory();
        final outPath = '${tmpDir.path}/mono_${project.id}.wav';
        final ok = await AudioAnalysisService.writeMonoWavFile(stereoPath, outPath);
        if (!mounted) return;
        setState(() => _isGeneratingMono = false);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.monoUnsupportedFormat)),
          );
          return;
        }
        _monoCache[project.id] = outPath;
        monoPath = outPath;
      }
      setState(() => _isMono = true);
      await ref.read(mobilePlayerProvider.notifier).switchSource(monoPath, savedPosition);
    } else {
      setState(() => _isMono = false);
      await ref.read(mobilePlayerProvider.notifier).switchSource(stereoPath, savedPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(mobilePlayerProvider);
    final providerQueue = ref.watch(mobilePlayerQueueProvider);
    // Bind the swipeable queue to the player's ordered queue so swiping follows
    // the play order (respecting shuffle); fall back to the dashboard list only
    // until playback has started.
    final orderedQueue =
        playerState.queue.isNotEmpty ? playerState.queue : providerQueue;
    // The player's queue holds project snapshots taken when playback started,
    // so an edit made since (notes, phase, name) would otherwise never show up
    // here. Re-resolve each entry against the repository, keeping play order.
    final latestProjects = ref.watch(allProjectsStreamProvider).asData?.value;
    final queue = freshestProjects(orderedQueue, latestProjects);
    final currentProject =
        freshestProject(playerState.currentProject, latestProjects);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Reage apenas quando o queueIndex muda (ex: auto-advance ao fim da faixa).
    // addPostFrameCallback causava race condition com múltiplos rebuilds.
    ref.listen<MobilePlayerState>(mobilePlayerProvider, (prev, next) {
      if (prev?.queueIndex != next.queueIndex) {
        final id = next.currentProject?.id;
        setState(() {
          _isMono = id != null &&
              ref.read(mobilePlayerProvider.notifier).hasSourceOverrideFor(id);
        });
        _syncPageToState(next.queueIndex);
      }
    });

    final currentPath = currentProject?.previewSongPath?.isNotEmpty == true
        ? currentProject!.previewSongPath
        : currentProject?.previewSongAutoPath;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.nowPlaying, style: theme.textTheme.titleMedium),
        centerTitle: true,
        actions: [
          if (currentProject != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: l10n.projectDetails,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(
                    projectId: currentProject.id,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 400) Navigator.of(context).maybePop();
        },
        behavior: HitTestBehavior.translucent,
        child: queue.isEmpty
          ? Center(child: Text(l10n.noPreviewSongsAvailable))
          : Column(
              children: [
                // ── PageView: swipe left/right to change track ──────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: queue.length,
                    onPageChanged: (page) => _onPageChanged(page, queue),
                    itemBuilder: (context, index) =>
                        _TrackCard(project: queue[index]),
                  ),
                ),

                // ── Controls ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      // Track name
                      Text(
                        currentProject?.displayName ?? '',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (queue.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${playerState.queueIndex + 1} / ${queue.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      _ProgressBar(
                        state: playerState,
                        previewPath: currentPath,
                      ),

                      const SizedBox(height: 12),

                      // ── Linha 1: Shuffle / Prev / −5s / Play / +5s / Next / Repeat ─
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ShuffleButton(mode: playerState.playbackMode),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_previous_rounded),
                              color: colorScheme.onSurface.withValues(
                                alpha: _canSkipPrev(playerState) ? 1.0 : 0.3,
                              ),
                              onPressed: _canSkipPrev(playerState)
                                  ? () => ref.read(mobilePlayerProvider.notifier).playPrev()
                                  : null,
                            ),
                            IconButton(
                              iconSize: 26,
                              tooltip: '−5s',
                              icon: const Icon(Icons.replay_5_rounded),
                              onPressed: () => _seekBy(-5),
                            ),
                            _PlayPauseButton(isPlaying: playerState.isPlaying),
                            IconButton(
                              iconSize: 26,
                              tooltip: '+5s',
                              icon: const Icon(Icons.forward_5_rounded),
                              onPressed: () => _seekBy(5),
                            ),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_next_rounded),
                              color: colorScheme.onSurface.withValues(
                                alpha: _canSkipNext(playerState, queue) ? 1.0 : 0.3,
                              ),
                              onPressed: _canSkipNext(playerState, queue)
                                  ? () => ref.read(mobilePlayerProvider.notifier).playNext()
                                  : null,
                            ),
                            _RepeatButton(mode: playerState.playbackMode),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Linha 2: Mono | espaço | Share / Download / Playlist ─
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            // Mono (esquerda)
                            if (_supportsMonoMix(currentPath))
                              _isGeneratingMono
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 14, height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(AppLocalizations.of(context)!.monoGenerating, style: theme.textTheme.bodySmall),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: _toggleMono,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _isMono
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _isMono
                                                ? colorScheme.primary
                                                : colorScheme.onSurface
                                                    .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          'MONO',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: _isMono
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    )
                            else
                              const SizedBox(width: 48),

                            const Spacer(),

                            // Add task at timestamp (left of Share)
                            if (currentProject != null)
                              IconButton(
                                iconSize: 22,
                                tooltip: l10n.addTaskAtTimestamp,
                                icon: const Icon(Icons.playlist_add_rounded),
                                color: colorScheme.onSurface,
                                onPressed: _openAddTodoSheet,
                              ),

                            // Share / Download / Playlist (direita)
                            if (currentPath != null &&
                                !currentPath.startsWith('drive://')) ...[
                              IconButton(
                                iconSize: 22,
                                tooltip: l10n.share,
                                icon: const Icon(Icons.share_rounded),
                                color: colorScheme.onSurface,
                                onPressed: _sharePreviewSong,
                              ),
                              IconButton(
                                iconSize: 22,
                                tooltip: l10n.shareZip,
                                icon: const Icon(Icons.folder_zip_rounded),
                                color: colorScheme.onSurface,
                                onPressed: _sharePreviewSongAsZip,
                              ),
                            ],
                            if (queue.length > 1)
                              IconButton(
                                iconSize: 22,
                                tooltip: l10n.upNext,
                                icon: const Icon(Icons.queue_music_rounded),
                                color: colorScheme.onSurface,
                                onPressed: () => _showQueueSheet(
                                    context, queue, playerState.queueIndex),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

// ── Project info card (shown in the PageView area) ───────────────────────────

class _TrackCard extends StatelessWidget {
  final MusicProject project;
  const _TrackCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + DAW badge row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.music_note_rounded, size: 28, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.dawType != null && project.dawType!.isNotEmpty)
                        Text(
                          project.dawType!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      if (project.status.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            project.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // BPM + Key row
            if (project.bpm != null || (project.musicalKey != null && project.musicalKey!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    if (project.bpm != null) ...[
                      _InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${project.bpm!.toStringAsFixed(project.bpm! % 1 == 0 ? 0 : 1)} BPM',
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (project.musicalKey != null && project.musicalKey!.isNotEmpty)
                      _InfoChip(
                        icon: Icons.piano_rounded,
                        label: project.musicalKey!,
                      ),
                  ],
                ),
              ),

            // Notes — user-typed and DAW-extracted, same as the desktop
            // player (#105). The big-display-name fallback below now applies
            // only when neither has anything.
            if (ProjectNotesSection.hasContent(
              userNotes: project.notes,
              dawNotes: project.projectNotes,
            ))
              Expanded(
                child: SingleChildScrollView(
                  child: ProjectNotesSection(
                    userNotes: project.notes,
                    dawNotes: project.projectNotes,
                    userNotesLabel: l10n.playerNotes,
                    // Same label the project detail page uses for this field,
                    // verbatim — one name for one thing across the app.
                    dawNotesLabel: l10n.projectNotesFromDaw,
                    expandLabel: l10n.expand,
                    collapseLabel: l10n.collapse,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                      height: 1.55,
                    ),
                    labelPadding: const EdgeInsets.only(top: 12, bottom: 4),
                    textPadding: const EdgeInsets.only(bottom: 8),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    project.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Age
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  project.projectAgeFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Whether a preview-song [path] is a real local file the waveform extractor
/// can be pointed at — i.e. set, and not a `drive://` reference for a file
/// that hasn't been downloaded to this device yet.
@visibleForTesting
bool isAnalyzablePreviewPath(String? path) =>
    path != null && path.isNotEmpty && !path.startsWith('drive://');

/// Builds the stored text for a todo added from the player, prefixing the
/// playback position as `[m:ss] ` so the entry records exactly where in the
/// track it was created.
String buildTimestampedTodoText(Duration position, String text) {
  return '[${formatDuration(position)}] ${text.trim()}';
}

// ── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends ConsumerStatefulWidget {
  final MobilePlayerState state;

  /// The current track's preview file. Used to render a real waveform (the
  /// same one the desktop players show) instead of a plain slider — falls
  /// back to a thin seek bar while peaks load or when the file can't be
  /// analysed (a not-yet-downloaded `drive://` reference, or a format with
  /// no mobile decoder — only WAV and MP3 have one).
  final String? previewPath;

  const _ProgressBar({required this.state, required this.previewPath});

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  WaveformPeaks? _peaks;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _loadPeaks();
  }

  @override
  void didUpdateWidget(_ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewPath != oldWidget.previewPath) _loadPeaks();
  }

  void _loadPeaks() {
    final path = widget.previewPath;
    if (!isAnalyzablePreviewPath(path)) {
      if (_peaks != null || _loadedFor != null) {
        setState(() {
          _peaks = null;
          _loadedFor = null;
        });
      }
      return;
    }
    if (path == _loadedFor) return;
    _loadedFor = path;
    setState(() => _peaks = null);
    ref.read(waveformCacheProvider.notifier).getOrExtract(path!).then((peaks) {
      if (mounted && _loadedFor == path) setState(() => _peaks = peaks);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final total = state.duration.inMilliseconds;
    final pos = state.position.inMilliseconds;
    final progress = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        WaveformWidget(
          peaks: _peaks,
          progress: progress,
          height: 52,
          onSeek: total > 0
              ? (p) => ref
                  .read(mobilePlayerProvider.notifier)
                  .seek(Duration(milliseconds: (p * total).round()))
              : null,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(state.position),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(formatDuration(state.duration),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Play/Pause button ─────────────────────────────────────────────────────────

class _PlayPauseButton extends ConsumerWidget {
  final bool isPlaying;
  const _PlayPauseButton({required this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => ref.read(mobilePlayerProvider.notifier).togglePlayPause(),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: colorScheme.onPrimary,
          size: 36,
        ),
      ),
    );
  }
}

// ── Playback helpers ──────────────────────────────────────────────────────────

bool _canSkipPrev(MobilePlayerState s) =>
    s.playbackMode == PlaybackMode.repeatAll ||
    s.playbackMode == PlaybackMode.shuffle ||
    s.queueIndex > 0;

bool _canSkipNext(MobilePlayerState s, List<MusicProject> queue) =>
    s.playbackMode == PlaybackMode.repeatAll ||
    s.playbackMode == PlaybackMode.shuffle ||
    s.queueIndex < queue.length - 1;

// ── Cor de marca compartilhada pelos botões de modo ──────────────────────────
const _kBrandOrange = Color(0xFFFF6100);

// ── Shuffle button ────────────────────────────────────────────────────────────

class _ShuffleButton extends ConsumerWidget {
  final PlaybackMode mode;
  const _ShuffleButton({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = mode == PlaybackMode.shuffle;
    return IconButton(
      iconSize: 28,
      tooltip: AppLocalizations.of(context)!.playbackModeShuffle,
      icon: const Icon(Icons.shuffle_rounded),
      color: active ? _kBrandOrange : colorScheme.onSurface,
      onPressed: () => ref.read(mobilePlayerProvider.notifier).setPlaybackMode(
            active ? PlaybackMode.normal : PlaybackMode.shuffle,
          ),
    );
  }
}

// ── Repeat button ─────────────────────────────────────────────────────────────

class _RepeatButton extends ConsumerWidget {
  final PlaybackMode mode;
  const _RepeatButton({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, active, next) = switch (mode) {
      PlaybackMode.normal    => (Icons.repeat_rounded,     false, PlaybackMode.repeatOne),
      PlaybackMode.repeatOne => (Icons.repeat_one_rounded, true,  PlaybackMode.repeatAll),
      PlaybackMode.repeatAll => (Icons.repeat_rounded,     true,  PlaybackMode.normal),
      PlaybackMode.shuffle   => (Icons.repeat_rounded,     false, PlaybackMode.repeatOne),
    };

    return IconButton(
      iconSize: 28,
      tooltip: AppLocalizations.of(context)!.playbackModeRepeat,
      icon: Icon(icon),
      color: active ? _kBrandOrange : colorScheme.onSurface,
      onPressed: () =>
          ref.read(mobilePlayerProvider.notifier).setPlaybackMode(next),
    );
  }
}

// ── Queue bottom sheet ────────────────────────────────────────────────────────

class _QueueSheet extends ConsumerWidget {
  final List<MusicProject> queue;
  final int currentIdx;
  final ScrollController scrollController;

  const _QueueSheet({
    required this.queue,
    required this.currentIdx,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.queue_music_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.upNext,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: queue.length,
            itemBuilder: (ctx, idx) {
              final project = queue[idx];
              final isCurrent = idx == currentIdx;
              return ListTile(
                selected: isCurrent,
                selectedTileColor: cs.primary.withValues(alpha: 0.08),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? cs.primary.withValues(alpha: 0.15)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isCurrent
                      ? Icon(Icons.equalizer_rounded, size: 18, color: cs.primary)
                      : Center(
                          child: Text(
                            '${idx + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                title: Text(
                  project.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                    color: isCurrent ? cs.primary : null,
                  ),
                ),
                subtitle: project.status.isNotEmpty
                    ? Text(
                        project.status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    : null,
                onTap: () {
                  final path = project.previewSongPath?.isNotEmpty == true
                      ? project.previewSongPath!
                      : project.previewSongAutoPath;
                  if (path == null) return;
                  ref.read(mobilePlayerProvider.notifier).playProject(
                        project,
                        path,
                        queue: queue,
                        queueIndex: idx,
                      );
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
