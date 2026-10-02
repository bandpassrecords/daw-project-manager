import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_piano_roll.dart';
import 'widgets/midi_volume_control.dart';

/// Opens [clip] in a large piano roll, with transport wired to [player].
///
/// Starting playback is the caller's own [onPlay] — the same function the
/// clip row's play button calls — so the instrument, tempo and error
/// handling are exactly what the list uses; pause, resume and stop go to
/// [player] directly. Space plays and pauses, Ctrl/Cmd+C copies.
///
/// [onCopy] and [onOpenProject] add their buttons when given. Opening the
/// project closes this window and stops the preview first.
Future<void> showMidiPianoRoll(
  BuildContext context, {
  required MidiClip clip,
  required String title,
  String? subtitle,
  required MidiPreviewPlayer player,
  required String playerKey,
  required double bpm,
  required VoidCallback onPlay,
  VoidCallback? onCopy,
  VoidCallback? onOpenProject,
}) {
  final l10n = AppLocalizations.of(context)!;
  final body = MidiPianoRollWindow(
    clip: clip,
    title: title,
    subtitle: subtitle,
    player: player,
    playerKey: playerKey,
    bpm: bpm,
    onPlay: onPlay,
    onCopy: onCopy,
    onOpenProject: onOpenProject,
    labels: MidiPianoRollWindowLabels(
      roll: MidiPianoRollLabels(
        zoomIn: l10n.midiPianoRollZoomIn,
        zoomOut: l10n.midiPianoRollZoomOut,
        fit: l10n.midiPianoRollFit,
        follow: l10n.midiPianoRollFollow,
      ),
      close: l10n.close,
      play: l10n.midiClipPlay,
      pause: l10n.midiPianoRollPause,
      stop: l10n.midiClipStop,
      copy: l10n.midiClipCopy,
      openProject: l10n.midiOpenSourceProject,
    ),
  );
  // The shared preview volume, live: the window's slider and the list's move
  // together, and either one changes what is playing.
  final withVolume = Consumer(
    builder: (context, ref, _) {
      final volume = ref.watch(midiPreviewVolumeProvider);
      return MidiPianoRollWindow.copyOf(
        body,
        volume: volume,
        onVolumeChanged: (v) {
          ref.read(midiPreviewVolumeProvider.notifier).set(v);
          player.setVolume(v);
        },
        volumeLabels: MidiVolumeLabels(
          volume: l10n.midiPreviewVolume,
          mute: l10n.volumeMute,
          unmute: l10n.volumeUnmute,
        ),
      );
    },
  );
  return showDialog<void>(
    context: context,
    builder: (context) {
      if (MobileUtils.isMobile()) return Dialog.fullscreen(child: withVolume);
      final size = MediaQuery.sizeOf(context);
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: size.width * 0.9,
          height: size.height * 0.85,
          child: withVolume,
        ),
      );
    },
  );
}

class MidiPianoRollWindowLabels {
  const MidiPianoRollWindowLabels({
    required this.roll,
    required this.close,
    required this.play,
    required this.pause,
    required this.stop,
    required this.copy,
    required this.openProject,
  });

  final MidiPianoRollLabels roll;
  final String close, play, pause, stop, copy, openProject;
}

/// The contents of [showMidiPianoRoll]'s window — public so it can be tested
/// without a dialog route around it.
class MidiPianoRollWindow extends StatelessWidget {
  const MidiPianoRollWindow({
    super.key,
    required this.clip,
    required this.title,
    required this.subtitle,
    required this.player,
    required this.playerKey,
    required this.bpm,
    required this.onPlay,
    required this.labels,
    this.onCopy,
    this.onOpenProject,
    this.volume,
    this.onVolumeChanged,
    this.volumeLabels,
  });

  /// [base] with a volume control added.
  factory MidiPianoRollWindow.copyOf(
    MidiPianoRollWindow base, {
    required double volume,
    required ValueChanged<double> onVolumeChanged,
    required MidiVolumeLabels volumeLabels,
  }) =>
      MidiPianoRollWindow(
        clip: base.clip,
        title: base.title,
        subtitle: base.subtitle,
        player: base.player,
        playerKey: base.playerKey,
        bpm: base.bpm,
        onPlay: base.onPlay,
        labels: base.labels,
        onCopy: base.onCopy,
        onOpenProject: base.onOpenProject,
        volume: volume,
        onVolumeChanged: onVolumeChanged,
        volumeLabels: volumeLabels,
      );

  /// The shared preview volume; the control shows only when all three of
  /// [volume], [onVolumeChanged] and [volumeLabels] are given.
  final double? volume;
  final ValueChanged<double>? onVolumeChanged;
  final MidiVolumeLabels? volumeLabels;

  final MidiClip clip;
  final String title;
  final String? subtitle;
  final MidiPreviewPlayer player;
  final String playerKey;
  final double bpm;
  final VoidCallback onPlay;
  final VoidCallback? onCopy;
  final VoidCallback? onOpenProject;
  final MidiPianoRollWindowLabels labels;

  bool get _isOurs => player.playingKey == playerKey;

  /// Space: start, pause, or resume.
  void _playPause() {
    if (!_isOurs) {
      onPlay();
    } else if (player.paused) {
      player.resume();
    } else {
      player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _playPause,
        if (onCopy != null) ...{
          const SingleActivator(LogicalKeyboardKey.keyC, control: true): onCopy!,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true): onCopy!,
        },
      },
      // Autofocus so Space works the moment the window opens, before anything
      // inside it has been clicked.
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListenableBuilder(
                    listenable: player,
                    builder: (context, _) {
                      if (player.preparingKey == playerKey) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final running = _isOurs && !player.paused;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: running ? labels.pause : labels.play,
                            iconSize: 32,
                            icon: Icon(running
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline),
                            onPressed: _playPause,
                          ),
                          if (_isOurs)
                            IconButton(
                              tooltip: labels.stop,
                              icon: const Icon(Icons.stop_circle_outlined),
                              onPressed: player.stop,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (volume != null &&
                      onVolumeChanged != null &&
                      volumeLabels != null)
                    MidiVolumeControl(
                      volume: volume!,
                      onChanged: onVolumeChanged!,
                      labels: volumeLabels!,
                      sliderWidth: 90,
                    ),
                  if (onCopy != null)
                    IconButton(
                      tooltip: labels.copy,
                      icon: const Icon(Icons.copy),
                      onPressed: onCopy,
                    ),
                  if (onOpenProject != null)
                    IconButton(
                      tooltip: labels.openProject,
                      icon: const Icon(Icons.assignment),
                      onPressed: () {
                        player.stop();
                        Navigator.of(context).pop();
                        onOpenProject!();
                      },
                    ),
                  IconButton(
                    tooltip: labels.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: MidiPianoRoll(
                  clip: clip,
                  bpm: bpm,
                  labels: labels.roll,
                  positionOf: () => player.positionOf(playerKey),
                  playback: player,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
