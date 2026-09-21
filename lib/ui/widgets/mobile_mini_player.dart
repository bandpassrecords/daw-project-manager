import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io';

import '../../models/music_project.dart';
import '../../providers/providers.dart';
import '../../utils/project_artwork.dart';
import '../mobile_player_page.dart';

/// Barra estilo SoundCloud que aparece acima do NavigationBar quando há
/// uma faixa tocando no mobile. Toque abre o [MobilePlayerPage] completo.
class MobileMiniPlayer extends ConsumerStatefulWidget {
  const MobileMiniPlayer({super.key});

  @override
  ConsumerState<MobileMiniPlayer> createState() => _MobileMiniPlayerState();
}

class _MobileMiniPlayerState extends ConsumerState<MobileMiniPlayer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  // direction of last completed swipe: -1 = left, +1 = right, 0 = none
  int _slideDirection = 0;

  static const _threshold = 200.0; // px/s
  static const _maxDrag = 80.0; // visual cap for drag offset

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragOffset = (_dragOffset + d.delta.dx).clamp(-_maxDrag, _maxDrag));
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -_threshold) {
      setState(() { _slideDirection = -1; _dragOffset = 0; });
      ref.read(mobilePlayerProvider.notifier).playNext();
    } else if (v > _threshold) {
      setState(() { _slideDirection = 1; _dragOffset = 0; });
      ref.read(mobilePlayerProvider.notifier).playPrev();
    } else {
      setState(() { _dragOffset = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mobilePlayerProvider);
    if (!state.hasTrack) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = state.duration.inMilliseconds;
    final progress =
        total > 0 ? (state.position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;

    // Build the slide transition for the text when a new track starts.
    final slideBegin = Offset(_slideDirection == 0 ? 0 : (_slideDirection < 0 ? 0.5 : -0.5), 0);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        mobilePlayerPageRoute(),
      ),
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300) {
          // swipe up → abrir full player
          Navigator.of(context).push(
            mobilePlayerPageRoute(),
          );
        } else if (v > 300 && !state.isPlaying) {
          // swipe down enquanto pausado → parar e esconder
          ref.read(mobilePlayerProvider.notifier).stop();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Main row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                child: Row(
                  children: [
                    // Thumbnail of the playing track, or the note icon when
                    // it has none — same image the full player shows.
                    _MiniArtwork(project: state.currentProject),
                    const SizedBox(width: 10),

                    // Track name — slides during drag, AnimatedSwitcher on track change
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(_dragOffset * 0.6, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) => SlideTransition(
                            position: Tween<Offset>(
                              begin: slideBegin,
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: FadeTransition(opacity: animation, child: child),
                          ),
                          child: Text(
                            state.currentProject?.displayName ?? '',
                            key: ValueKey(state.currentProject?.id),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                    // Play / Pause button
                    _MiniPlayPauseButton(isPlaying: state.isPlaying),
                  ],
                ),
              ),

              // ── Thin progress bar at bottom ───────────────────────────
              LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayPauseButton extends ConsumerWidget {
  final bool isPlaying;
  const _MiniPlayPauseButton({required this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
        size: 36,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () =>
          ref.read(mobilePlayerProvider.notifier).togglePlayPause(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// The mini player's 38 px cover: the track's thumbnail when it has one,
/// otherwise the tinted note tile this bar has always shown.
class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.project});

  final MusicProject? project;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbnail =
        project == null ? null : resolveProjectThumbnail(project!);

    if (thumbnail == null) return _fallback(colorScheme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(thumbnail),
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(colorScheme),
      ),
    );
  }

  Widget _fallback(ColorScheme colorScheme) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      color: colorScheme.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.music_note_rounded,
      size: 22,
      color: colorScheme.primary,
    ),
  );
}
