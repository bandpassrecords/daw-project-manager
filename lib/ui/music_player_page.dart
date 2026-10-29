import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../services/camelot_playlist_generator.dart';
import '../utils/deadline_text.dart';
import '../utils/playback_todo_utils.dart';
import '../utils/project_freshness.dart';
import 'camelot_wheel_widget.dart';
import 'marker_navigation.dart';
import 'project_detail_page.dart';
import 'widgets/project_markers_section.dart';
import 'widgets/player_queue_header.dart';
import 'widgets/project_notes_section.dart';
import 'app_snack_bar.dart';

enum _PlayerLoopMode { none, repeatAll, shuffle }

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = -1;
  List<MusicProject> _tracks = [];
  String _searchQuery = '';
  late TextEditingController _searchController;
  double _sidebarWidth = 320.0;
  double _queueWidth = 280.0;
  double _wheelSize = 280.0;

  final List<MusicProject> _playlist = [];
  int _playlistIndex = -1;
  bool _playingFromPlaylist = false;
  _PlayerLoopMode _loopMode = _PlayerLoopMode.none;

  int _selectedIndex = -1;
  final TextEditingController _addTodoController = TextEditingController();

  // Manual double-click detection — avoids DoubleTapGestureRecognizer in the arena.
  DateTime? _lastTapTime;
  int _lastTapKey = -1; // library: originalIndex, queue: ~i (bitwise not)

  MusicProject? get _current =>
      _currentIndex >= 0 && _currentIndex < _tracks.length
          ? _tracks[_currentIndex]
          : null;

  List<(int, MusicProject)> get _displayTracks {
    if (_searchQuery.isEmpty) {
      return List.generate(_tracks.length, (i) => (i, _tracks[i]));
    }
    final q = _searchQuery.toLowerCase();
    return [
      for (int i = 0; i < _tracks.length; i++)
        if (_tracks[i].displayName.toLowerCase().contains(q) ||
            p.basename(_resolvedPath(_tracks[i]) ?? '').toLowerCase().contains(q))
          (i, _tracks[i]),
    ];
  }

  String? _resolvedPath(MusicProject project) =>
      project.previewSongPath?.isNotEmpty == true
          ? project.previewSongPath
          : project.previewSongAutoPath;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Seed the track list from whatever the stream already holds on first mount.
      final value = ref.read(allProjectsStreamProvider).value;
      if (value != null) _buildTrackList(value);
      // Register queue navigation callbacks for the bottom player bar.
      final navigation = ref.read(queueNavigationProvider.notifier);
      navigation.register(playNext: _playNext, playPrev: _playPrev);
      _queueNavigation = navigation;
    });
  }

  /// Kept from registering: `ref` can't be used in [dispose] — it threw
  /// there on every unmount, so the callbacks were never taken back and
  /// this State's own dispose never finished.
  QueueNavigationNotifier? _queueNavigation;

  @override
  void dispose() {
    _searchController.dispose();
    _addTodoController.dispose();
    // After the frame: providers can't change while the tree is torn down.
    final navigation = _queueNavigation;
    final playNext = _playNext;
    if (navigation != null) Future.microtask(() => navigation.unregister(playNext));
    super.dispose();
  }

  Future<void> _addTodo(MusicProject project, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _addTodoController.clear();
    // If the task's project is the one actually playing right now, stamp it
    // with the current playback position — same convention as the bottom
    // player bar's "add task at timestamp" action.
    final todoText = buildTaskTextForProject(
      isCurrentlyPlaying:
          ref.read(desktopPlayerProvider)?.project.id == project.id,
      position: ref.read(desktopPlayerPositionProvider),
      text: trimmed,
    );
    final newTodo = TodoItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      text: todoText,
      createdAt: DateTime.now(),
    );
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(project.copyWith(
      todos: [...project.todos, newTodo],
    ));
    ref.invalidate(allProjectsStreamProvider);
  }

  void _buildTrackList(List<MusicProject> projects) {
    final tracks = projects
        .where((p) => _resolvedPath(p) != null)
        .toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));

    // Skip rebuild when nothing the UI cares about has changed. This compares
    // updatedAt, so an edit made elsewhere — notes, DAW notes, BPM, phase —
    // reaches the detail pane instead of being skipped as "same track list".
    if (!trackListChanged(_tracks, tracks)) return;

    setState(() {
      final prevCurrentId = _current?.id;
      final prevSelectedId = _selectedIndex >= 0 && _selectedIndex < _tracks.length
          ? _tracks[_selectedIndex].id
          : null;
      _tracks = tracks;
      // The queue holds its own snapshots, taken when each track was queued.
      // Re-resolve them against the new list so the queue panel shows the same
      // up-to-date names and phases as the library, keeping queue order.
      final refreshedQueue = freshestProjects(_playlist, tracks);
      for (int i = 0; i < _playlist.length; i++) {
        _playlist[i] = refreshedQueue[i];
      }
      if (prevCurrentId != null) {
        final idx = _tracks.indexWhere((t) => t.id == prevCurrentId);
        _currentIndex = idx >= 0 ? idx : _currentIndex.clamp(-1, _tracks.length - 1);
      }
      if (prevSelectedId != null) {
        final idx = _tracks.indexWhere((t) => t.id == prevSelectedId);
        if (idx >= 0) _selectedIndex = idx;
      }
    });
  }

  void _selectTrack(int index, {bool keepPlaylistState = false}) {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    final filePath = _resolvedPath(track)!;
    setState(() {
      _currentIndex = index;
      _selectedIndex = index;
      if (!keepPlaylistState) _playingFromPlaylist = false;
    });
    ref.read(desktopPlayerProvider.notifier).play(track, filePath, isQueuedPlayback: true);
  }

  void _selectFromPlaylist(int pi) {
    if (pi < 0 || pi >= _playlist.length) return;
    final project = _playlist[pi];
    final idx = _tracks.indexWhere((t) => t.id == project.id);
    if (idx < 0) return;
    setState(() {
      _playlistIndex = pi;
      _playingFromPlaylist = true;
    });
    _selectTrack(idx, keepPlaylistState: true);
  }

  int _randomIndex(int length, int exclude) {
    if (length <= 1) return 0;
    int next;
    do {
      next = math.Random().nextInt(length);
    } while (next == exclude);
    return next;
  }

  void _stopPlayback() {
    ref.read(desktopPlayerProvider.notifier).close();
    setState(() {
      _currentIndex = -1;
      _playlistIndex = -1;
      _playingFromPlaylist = false;
    });
  }

  void _playNext() {
    if (_playingFromPlaylist && _playlist.isNotEmpty) {
      switch (_loopMode) {
        case _PlayerLoopMode.shuffle:
          _selectFromPlaylist(_randomIndex(_playlist.length, _playlistIndex));
        case _PlayerLoopMode.repeatAll:
          _selectFromPlaylist((_playlistIndex + 1) % _playlist.length);
        case _PlayerLoopMode.none:
          if (_playlistIndex >= _playlist.length - 1) {
            _stopPlayback();
          } else {
            _selectFromPlaylist(_playlistIndex + 1);
          }
      }
    } else {
      if (_tracks.isEmpty) return;
      switch (_loopMode) {
        case _PlayerLoopMode.shuffle:
          _selectTrack(_randomIndex(_tracks.length, _currentIndex));
        case _PlayerLoopMode.repeatAll:
          _selectTrack((_currentIndex + 1) % _tracks.length);
        case _PlayerLoopMode.none:
          if (_currentIndex >= _tracks.length - 1) {
            _stopPlayback();
          } else {
            _selectTrack(_currentIndex + 1);
          }
      }
    }
  }

  void _playPrev() {
    if (_playingFromPlaylist && _playlist.isNotEmpty) {
      switch (_loopMode) {
        case _PlayerLoopMode.shuffle:
          _selectFromPlaylist(_randomIndex(_playlist.length, _playlistIndex));
        case _PlayerLoopMode.repeatAll:
          _selectFromPlaylist((_playlistIndex - 1 + _playlist.length) % _playlist.length);
        case _PlayerLoopMode.none:
          _selectFromPlaylist((_playlistIndex - 1).clamp(0, _playlist.length - 1));
      }
    } else {
      if (_tracks.isEmpty) return;
      switch (_loopMode) {
        case _PlayerLoopMode.shuffle:
          _selectTrack(_randomIndex(_tracks.length, _currentIndex));
        case _PlayerLoopMode.repeatAll:
          _selectTrack((_currentIndex - 1 + _tracks.length) % _tracks.length);
        case _PlayerLoopMode.none:
          _selectTrack((_currentIndex - 1).clamp(0, _tracks.length - 1));
      }
    }
  }

  void _showCamelotDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligible = CamelotPlaylistGenerator.eligibleCount(_tracks);
    final skipped = _tracks.length - eligible;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.camelotDialogTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.camelotDialogDescription,
                  style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (eligible > 0) ...[
                _CamelotStatRow(
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade400,
                  label: l10n.camelotEligibleTracks(eligible),
                ),
                if (skipped > 0) ...[
                  const SizedBox(height: 6),
                  _CamelotStatRow(
                    icon: Icons.info_outline,
                    color: Colors.orange.shade400,
                    label: l10n.camelotSkippedTracks(skipped),
                  ),
                ],
              ] else
                Text(l10n.camelotNoEligibleTracks,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.error,
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          if (eligible > 0)
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(l10n.camelotGenerate),
              onPressed: () {
                final result = CamelotPlaylistGenerator.generate(_tracks);
                Navigator.of(ctx).pop();
                setState(() {
                  _playlist
                    ..clear()
                    ..addAll(result.ordered);
                  _playlistIndex = -1;
                  _playingFromPlaylist = false;
                });
                ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(
                  content: Text(l10n.camelotQueueGenerated(result.ordered.length)),
                  duration: const Duration(seconds: 3),
                ));
              },
            ),
        ],
      ),
    );
  }

  void _showCamelotWheelGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.camelotWheelGuideTitle),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GuideSection(
                  title: l10n.camelotGuideRingsTitle,
                  body: l10n.camelotGuideRingsBody,
                ),
                const SizedBox(height: 14),
                _GuideSection(
                  title: l10n.camelotGuideNumbersTitle,
                  body: l10n.camelotGuideNumbersBody,
                ),
                const SizedBox(height: 14),
                _GuideSection(
                  title: l10n.camelotGuideColoursTitle,
                  body: l10n.camelotGuideColoursBody,
                ),
                const SizedBox(height: 14),
                _GuideSection(
                  title: l10n.camelotGuideTransitionsTitle,
                  body: l10n.camelotGuideTransitionsBody,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  void _showTrackContextMenu(BuildContext context, Offset globalPos, MusicProject track, int originalIndex) {
    final l10n = AppLocalizations.of(context)!;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'detail',
          child: Row(children: [
            const Icon(Icons.assignment, size: 16),
            const SizedBox(width: 10),
            Text(l10n.playerGoToProject),
          ]),
        ),
        if (!_playlist.any((t) => t.id == track.id))
          PopupMenuItem(
            value: 'queue',
            child: Row(children: [
              const Icon(Icons.queue_music, size: 16),
              const SizedBox(width: 10),
              Text(l10n.playerAddToQueue),
            ]),
          ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'detail') {
        navigator.push(
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: track.id)),
        );
      } else if (value == 'queue') {
        setState(() => _playlist.add(track));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(allProjectsStreamProvider, (_, next) {
      _buildTrackList(next.value ?? []);
    });
    ref.listen(desktopPlayerCompletedProvider, (prev, next) {
      if (_currentIndex >= 0 || _playingFromPlaylist) _playNext();
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        // ── Left: track library ───────────────────────────────────────────
        SizedBox(
          width: _sidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.headphones, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(l10n.playerTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _searchQuery.isEmpty
                          ? l10n.playerTrackCount(_tracks.length)
                          : l10n.playerTrackCountFiltered(_displayTracks.length, _tracks.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.playerSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _tracks.isEmpty
                    ? Center(
                        child: Text(
                          l10n.playerNoPreviewSongs,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : _displayTracks.isEmpty
                        ? Center(
                            child: Text(
                              l10n.playerNoTracksMatch(_searchQuery),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _displayTracks.length,
                            itemBuilder: (context, i) {
                              final (originalIndex, track) = _displayTracks[i];
                              final isCurrentTrack = originalIndex == _currentIndex;
                              final isActuallyPlaying = ref.watch(desktopIsPlayingProvider);
                              final isPlaying = isCurrentTrack && isActuallyPlaying;
                              final isPreviewing = originalIndex == _selectedIndex;
                              final resolvedPath = _resolvedPath(track)!;
                              return Draggable<MusicProject>(
                                data: track,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: _sidebarWidth - 32,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.music_note, size: 16,
                                            color: cs.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            track.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: ListTile(
                                    dense: true,
                                    selected: isPlaying || isPreviewing,
                                    selectedTileColor:
                                        cs.primary.withValues(alpha: 0.1),
                                    leading: Icon(Icons.music_note, size: 18,
                                        color: isPlaying ? cs.primary : null),
                                    title: Text(track.displayName,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    final now = DateTime.now();
                                    final isDouble = _lastTapKey == originalIndex &&
                                        _lastTapTime != null &&
                                        now.difference(_lastTapTime!) <
                                            const Duration(milliseconds: 350);
                                    _lastTapTime = isDouble ? null : now;
                                    _lastTapKey = originalIndex;
                                    if (isDouble) {
                                      setState(() {
                                        _playlist.clear();
                                        _playlist.add(track);
                                        _playlistIndex = 0;
                                        _playingFromPlaylist = true;
                                      });
                                      _selectTrack(originalIndex,
                                          keepPlaylistState: true);
                                    } else {
                                      setState(() {
                                        _selectedIndex = originalIndex;
                                        _addTodoController.clear();
                                      });
                                    }
                                  },
                                  onSecondaryTapUp: (details) =>
                                      _showTrackContextMenu(
                                          context,
                                          details.globalPosition,
                                          track,
                                          originalIndex),
                                  child: ListTile(
                                    dense: true,
                                    selected: isPlaying || isPreviewing,
                                    selectedTileColor: isPlaying
                                        ? cs.primary.withValues(alpha: 0.12)
                                        : cs.secondary.withValues(alpha: 0.08),
                                    leading: _PulsingIcon(
                                      isPlaying: isPlaying,
                                      glowColor: cs.primary,
                                      isPreviewing: isPreviewing,
                                      previewColor: cs.secondary,
                                    ),
                                    title: Text(
                                      track.displayName,
                                      style: TextStyle(
                                        fontWeight:
                                            isPlaying ? FontWeight.w600 : null,
                                        color: isPlaying ? cs.primary : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      p.basename(resolvedPath),
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        // ── Sidebar resize handle ─────────────────────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + d.delta.dx).clamp(180.0, 520.0);
              });
            },
            child: Container(
              width: 5,
              color: Colors.transparent,
              child: const VerticalDivider(width: 1),
            ),
          ),
        ),
        // ── Middle: project detail or hint ──────────────────────────────
        if (_selectedIndex >= 0 && _selectedIndex < _tracks.length)
          Expanded(child: _buildProjectDetail(context, _tracks[_selectedIndex]))
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 48,
                      color: cs.onSurface.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Text(l10n.playerDoubleClickToPlay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.35),
                      )),
                  const SizedBox(height: 6),
                  Text(l10n.playerSingleClickToPreview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.25),
                      )),
                ],
              ),
            ),
          ),
        // ── Queue resize handle ──────────────────────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              setState(() {
                _queueWidth = (_queueWidth - d.delta.dx).clamp(200.0, 520.0);
              });
            },
            child: Container(
              width: 5,
              color: Colors.transparent,
              child: const VerticalDivider(width: 1),
            ),
          ),
        ),
        // ── Right: queue ─────────────────────────────────────────────────
        SizedBox(width: _queueWidth, child: _buildPlaylistPanel(context)),
      ],
    );
  }

  Color _phaseColor(String status) => switch (status) {
        'Idea'       => Colors.blue.shade300,
        'Arranging'  => Colors.orange.shade300,
        'Mixing'     => Colors.purple.shade300,
        'Mastering'  => Colors.pink.shade300,
        'Finished'   => Colors.green.shade300,
        _            => Colors.grey,
      };

  Widget _buildProjectDetail(BuildContext context, MusicProject project) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final phaseColor = _phaseColor(project.status);
    final pending = project.todos.where((t) => !t.completed).toList();
    final done    = project.todos.where((t) =>  t.completed).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: phaseColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.displayName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _Chip(label: project.status, color: phaseColor),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.assignment, size: 16),
                  tooltip: l10n.playerGoToProject,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProjectDetailPage(projectId: project.id),
                  )),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: l10n.playerDismissDetail,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _selectedIndex = -1),
                ),
              ],
            ),
          ),
          // ── Meta row (BPM · Key · Deadline) ─────────────────────────────
          if (project.bpm != null || project.musicalKey != null || project.deadline != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (project.bpm != null)
                    _Chip(
                      label: '${project.bpm!.toStringAsFixed(project.bpm! == project.bpm!.roundToDouble() ? 0 : 1)} BPM',
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  if (project.musicalKey != null)
                    _Chip(
                      label: project.musicalKey!,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  if (project.camelotCode != null)
                    _Chip(
                      label: project.camelotCode!,
                      color: cs.primary.withValues(alpha: 0.7),
                    ),
                  if (project.deadline != null)
                    _Chip(
                      label: deadlineText(AppLocalizations.of(context)!, project.daysUntilDeadline ?? 0),
                      color: (project.daysUntilDeadline != null && project.daysUntilDeadline! < 0)
                          ? Colors.red.shade300
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          // ── Scrollable body ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Camelot wheel
                if (project.camelotCode != null)
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final maxAllowed = constraints.maxWidth - 32;
                      final size = _wheelSize.clamp(160.0, maxAllowed);
                      return Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                                child: Center(
                                  child: CamelotWheelWidget(
                                    activeCode: project.camelotCode!,
                                    compatibleCodes: project.compatibleCamelotCodes ?? [],
                                    size: size,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 4,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  tooltip: l10n.camelotWheelGuideTooltip,
                                  onPressed: () =>
                                      _showCamelotWheelGuide(context),
                                ),
                              ),
                            ],
                          ),
                          // Resize handle
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeUpDown,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (d) => setState(() {
                                _wheelSize = (_wheelSize + d.delta.dy)
                                    .clamp(160.0, maxAllowed);
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Center(
                                  child: Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (project.camelotCode != null) const Divider(height: 1),
                // Mix suggestions
                if (project.camelotCode != null) ...[
                  Builder(builder: (context) {
                    final compatible = _tracks.where((t) =>
                      t.id != project.id &&
                      t.camelotCode != null &&
                      (project.compatibleCamelotCodes ?? []).contains(t.camelotCode),
                    ).toList();
                    if (compatible.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                          child: Text(l10n.playerMixSuggestions,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 0.8,
                              )),
                        ),
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: compatible.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 6),
                            itemBuilder: (context, i) {
                              final t = compatible[i];
                              final idx = _tracks.indexOf(t);
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: idx >= 0
                                    ? () => setState(() => _selectedIndex = idx)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        t.camelotCode!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        t.displayName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                      ],
                    );
                  }),
                ],
                // Notes — what the user typed, and what was read out of the
                // DAW file itself (#105). Both labelled, always in that order.
                if (ProjectNotesSection.hasContent(
                  userNotes: project.notes,
                  dawNotes: project.projectNotes,
                )) ...[
                  ProjectNotesSection(
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
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  const Divider(height: 1),
                ],
                // Markers read out of the DAW file (#91) — a table of
                // contents for sessions holding more than one song. Tapping
                // one seeks this track, which is the point of them being here
                // rather than only on the detail page.
                if (project.markers.isNotEmpty) ...[
                  ProjectMarkersSection(
                    markers: project.markers,
                    title: l10n.projectMarkers,
                    unnamedMarkerLabel: l10n.projectMarkerUnnamed,
                    unnamedRegionLabel: l10n.projectRegionUnnamed,
                    showAllLabel: l10n.showAll,
                    collapseLabel: l10n.collapse,
                    jumpTooltip: l10n.projectMarkerJumpTooltip,
                    disabledTooltip: l10n.projectMarkerNoPreviewSong,
                    onTap: canJumpToProjectMarkers(project)
                        ? (marker) =>
                            jumpToProjectMarker(ref, project, marker)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                ],
                // Tasks header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(children: [
                    Text(l10n.playerTasks,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(width: 6),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${pending.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            )),
                      ),
                  ]),
                ),
                if (project.todos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(l10n.playerNoTasks,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        )),
                  )
                else ...[
                  ...pending.map((todo) => _DetailTodoItem(
                        project: project,
                        todo: todo,
                        onToggled: () => setState(() {}),
                      )),
                  if (done.isNotEmpty)
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      title: Text(
                        l10n.playerCompletedTasks(done.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      children: done.map((todo) => _DetailTodoItem(
                            project: project,
                            todo: todo,
                            onToggled: () => setState(() {}),
                          )).toList(),
                    ),
                ],
                // Add task input
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addTodoController,
                          style: theme.textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: l10n.playerAddTaskHint,
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2)),
                            ),
                          ),
                          onSubmitted: (v) => _addTodo(project, v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.playerAddTaskHint,
                        onPressed: () => _addTodo(project, _addTodoController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DragTarget<MusicProject>(
      onAcceptWithDetails: (details) {
        final track = details.data;
        if (!_playlist.any((t) => t.id == track.id)) {
          setState(() => _playlist.add(track));
        }
      },
      builder: (context, candidateData, _) {
        final isDraggingOver = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isDraggingOver ? cs.primary : theme.dividerColor,
              ),
            ),
            color: isDraggingOver ? cs.primary.withValues(alpha: 0.05) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                child: PlayerQueueHeader(
                  count: _playlist.length,
                  libraryActions: _tracks.isNotEmpty,
                  queueActions: _playlist.isNotEmpty,
                  shuffleOn: _loopMode == _PlayerLoopMode.shuffle,
                  repeatOn: _loopMode == _PlayerLoopMode.repeatAll,
                  onAutoQueue: () => _showCamelotDialog(context),
                  onShuffle: () => setState(() => _loopMode =
                      _loopMode == _PlayerLoopMode.shuffle
                          ? _PlayerLoopMode.none
                          : _PlayerLoopMode.shuffle),
                  onRepeat: () => setState(() => _loopMode =
                      _loopMode == _PlayerLoopMode.repeatAll
                          ? _PlayerLoopMode.none
                          : _PlayerLoopMode.repeatAll),
                  onPrevious: _playPrev,
                  onNext: _playNext,
                  onClear: () => setState(() {
                    _playlist.clear();
                    _playlistIndex = -1;
                    _playingFromPlaylist = false;
                  }),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _playlist.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.queue_music, size: 40,
                                  color: cs.onSurface.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.playerQueueEmptyHint,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _playlist.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final item = _playlist.removeAt(oldIndex);
                            _playlist.insert(newIndex, item);
                            if (_playlistIndex == oldIndex) {
                              _playlistIndex = newIndex;
                            } else if (oldIndex < _playlistIndex &&
                                newIndex >= _playlistIndex) {
                              _playlistIndex--;
                            } else if (oldIndex > _playlistIndex &&
                                newIndex <= _playlistIndex) {
                              _playlistIndex++;
                            }
                          });
                        },
                        itemBuilder: (context, i) {
                          final track = _playlist[i];
                          final isActive =
                              _playingFromPlaylist && i == _playlistIndex;
                          final isSelected = !isActive &&
                              _selectedIndex >= 0 &&
                              _selectedIndex < _tracks.length &&
                              _tracks[_selectedIndex].id == track.id;
                          final resolvedPath = _resolvedPath(track);
                          return GestureDetector(
                            key: ValueKey(track.id),
                            onTapDown: (_) {
                              final key = ~i; // negative namespace for queue items
                              final now = DateTime.now();
                              final isDouble = _lastTapKey == key &&
                                  _lastTapTime != null &&
                                  now.difference(_lastTapTime!) <
                                      const Duration(milliseconds: 350);
                              _lastTapTime = isDouble ? null : now;
                              _lastTapKey = key;
                              if (isDouble) {
                                if (resolvedPath != null) _selectFromPlaylist(i);
                              } else {
                                final idx = _tracks.indexWhere((t) => t.id == track.id);
                                if (idx >= 0) {
                                  setState(() {
                                    _selectedIndex = idx;
                                    _addTodoController.clear();
                                  });
                                }
                              }
                            },
                            onSecondaryTapUp: (details) {
                              final RenderBox overlay = Overlay.of(context)
                                  .context
                                  .findRenderObject()! as RenderBox;
                              final navigator = Navigator.of(context);
                              showMenu<String>(
                                context: context,
                                position: RelativeRect.fromRect(
                                  details.globalPosition & const Size(1, 1),
                                  Offset.zero & overlay.size,
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 'detail',
                                    child: Row(children: [
                                      const Icon(Icons.assignment, size: 16),
                                      const SizedBox(width: 10),
                                      Text(l10n.playerGoToProject),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(children: [
                                      const Icon(Icons.remove_circle_outline,
                                          size: 16),
                                      const SizedBox(width: 10),
                                      Text(l10n.playerRemoveFromQueue),
                                    ]),
                                  ),
                                ],
                              ).then((value) {
                                if (!mounted) return;
                                if (value == 'detail') {
                                  navigator.push(MaterialPageRoute(
                                    builder: (_) =>
                                        ProjectDetailPage(projectId: track.id),
                                  ));
                                } else if (value == 'remove') {
                                  setState(() {
                                    _playlist.removeAt(i);
                                    if (_playlistIndex >= _playlist.length) {
                                      _playlistIndex = _playlist.length - 1;
                                    }
                                  });
                                }
                              });
                            },
                            child: ListTile(
                              dense: true,
                              selected: isActive || isSelected,
                              selectedTileColor: isActive
                                  ? cs.primary.withValues(alpha: 0.1)
                                  : cs.secondary.withValues(alpha: 0.08),
                              leading: Icon(
                                isActive ? Icons.volume_up : Icons.music_note,
                                size: 16,
                                color: isActive
                                    ? cs.primary
                                    : isSelected
                                        ? cs.secondary
                                        : cs.onSurface.withValues(alpha: 0.4),
                              ),
                              title: Text(
                                track.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : null,
                                  color: isActive
                                      ? cs.primary
                                      : isSelected
                                          ? cs.secondary
                                          : null,
                                ),
                              ),
                              subtitle: Text(
                                p.basename(resolvedPath ?? ''),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() {
                                  _playlist.removeAt(i);
                                  if (_playlistIndex >= _playlist.length) {
                                    _playlistIndex = _playlist.length - 1;
                                  }
                                }),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CamelotStatRow extends StatelessWidget {
  const _CamelotStatRow({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(body, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DetailTodoItem extends ConsumerWidget {
  const _DetailTodoItem({
    required this.project,
    required this.todo,
    required this.onToggled,
  });
  final MusicProject project;
  final TodoItem todo;
  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      controlAffinity: ListTileControlAffinity.leading,
      value: todo.completed,
      title: Text(
        todo.text,
        style: TextStyle(
          fontSize: 13,
          decoration: todo.completed ? TextDecoration.lineThrough : null,
          color: todo.completed
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
        ),
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updated = project.copyWith(
          todos: project.todos.map((t) {
            if (t.id == todo.id) {
              return t.copyWith(completed: !t.completed);
            }
            return t;
          }).toList(),
        );
        await repo.updateProject(updated);
        ref.invalidate(allProjectsStreamProvider);
        onToggled();
      },
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final bool isPlaying;
  final bool isPreviewing;
  final Color glowColor;
  final Color previewColor;

  const _PulsingIcon({
    required this.isPlaying,
    required this.glowColor,
    required this.isPreviewing,
    required this.previewColor,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _anim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingIcon old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPlaying && old.isPlaying) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Icon(
        Icons.music_note,
        size: 18,
        color: widget.isPreviewing ? widget.previewColor : null,
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Positioned keeps the glow outside the layout footprint.
          Positioned(
            left: -3,
            right: -3,
            top: -3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.glowColor.withValues(alpha: _anim.value * 0.45),
              ),
            ),
          ),
          Icon(Icons.volume_up, size: 18, color: widget.glowColor),
        ],
      ),
    );
  }
}
