import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/plugin_capture.dart';
import '../../providers/providers.dart';
import '../../services/app_audio_focus.dart';
import '../../services/player_volume_store.dart';
import '../../utils/track_duration.dart';
import '../app_snack_bar.dart';
import 'semantics_safe.dart';

/// The project page's "Latest capture": the last pass the DAW plugin
/// recorded, beside the preview song and never in its place. Plays on its
/// own player, which joins [AppAudioFocus] like every other player.
class LatestCaptureSection extends ConsumerStatefulWidget {
  const LatestCaptureSection({super.key, required this.project});

  /// Drawn only when the project has a [MusicProject.latestCapture].
  final MusicProject project;

  @override
  ConsumerState<LatestCaptureSection> createState() => _LatestCaptureSectionState();
}

class _LatestCaptureSectionState extends ConsumerState<LatestCaptureSection> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _available = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  PluginCapture get _capture => widget.project.latestCapture!;

  @override
  void initState() {
    super.initState();
    AppAudioFocus.register(this, () {
      if (_player.state == PlayerState.playing) _player.pause();
    });
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
      if (state == PlayerState.playing) AppAudioFocus.claim(this);
    });
    _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
    _checkFile();
  }

  @override
  void didUpdateWidget(LatestCaptureSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.latestCapture?.path != widget.project.latestCapture?.path) {
      _player.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _checkFile();
    }
  }

  /// A capture synced from another device is on this one only once its file
  /// has come down.
  Future<void> _checkFile() async {
    final exists = await File(_capture.path).exists();
    if (mounted) setState(() => _available = exists);
  }

  @override
  void dispose() {
    _player.dispose();
    AppAudioFocus.unregister(this);
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_playing) {
      await _player.pause();
    } else if (_position > Duration.zero) {
      await _player.resume();
    } else {
      await _player.setVolume(PlayerVolumeStore.current);
      await _player.play(DeviceFileSource(_capture.path));
    }
  }

  Future<void> _useAsPreview() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(widget.project.copyWith(
      previewSongPath: _capture.path,
      previewSongFileName: p.basename(_capture.path),
    ));
    ref.invalidate(allProjectsStreamProvider);
    messenger.showAppSnackBar(SnackBar(content: Text(l10n.latestCaptureNowPreview)));
  }

  @override
  Widget build(BuildContext context) {
    return LatestCaptureView(
      capture: _capture,
      available: _available,
      playing: _playing,
      position: _position,
      duration: _duration,
      isPreviewSong: widget.project.previewSongPath == _capture.path,
      onPlayPause: _playPause,
      onSeek: (d) => _player.seek(d),
      onUseAsPreview: _useAsPreview,
    );
  }
}

/// What [LatestCaptureSection] draws: plain values in, so it is tested
/// without a player, Riverpod or Hive.
class LatestCaptureView extends StatelessWidget {
  const LatestCaptureView({
    super.key,
    required this.capture,
    required this.available,
    required this.playing,
    required this.position,
    required this.duration,
    required this.isPreviewSong,
    required this.onPlayPause,
    required this.onSeek,
    required this.onUseAsPreview,
  });

  final PluginCapture capture;

  /// The file is on this device (a synced one may not have come down yet).
  final bool available;
  final bool playing;
  final Duration position;

  /// As the player reports it; until then, the length the plugin recorded.
  final Duration duration;

  /// Already promoted: no point offering it again.
  final bool isPreviewSong;

  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onUseAsPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final length = duration > Duration.zero
        ? duration
        : Duration(milliseconds: (capture.durationSeconds * 1000).round());
    final when = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(capture.capturedAt.toLocal());
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.latestCaptureTitle, style: theme.textTheme.titleSmall),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.latestCaptureExplanation,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: dim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.latestCapturePlay,
                  icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                  iconSize: 32,
                  onPressed: available ? onPlayPause : null,
                ),
                Expanded(
                  child: SliderOverlay(
                    child: Slider(
                      value: position.inMilliseconds.clamp(0, length.inMilliseconds).toDouble(),
                      max: length.inMilliseconds > 0 ? length.inMilliseconds.toDouble() : 1,
                      onChanged: available && length > Duration.zero
                          ? (v) => onSeek(Duration(milliseconds: v.round()))
                          : null,
                    ),
                  ),
                ),
                Text(
                  '${formatTrackDuration(position)} / ${formatTrackDuration(length)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    available
                        ? l10n.latestCaptureDetails(when, formatTrackDuration(length))
                        : l10n.latestCaptureNotOnThisDevice,
                    style: theme.textTheme.bodySmall?.copyWith(color: dim),
                  ),
                ),
                if (!isPreviewSong)
                  TextButton.icon(
                    onPressed: available ? onUseAsPreview : null,
                    icon: const Icon(Icons.queue_music, size: 18),
                    label: Text(l10n.latestCaptureUseAsPreview),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
