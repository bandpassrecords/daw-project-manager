import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../utils/mobile_utils.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_piano_roll.dart';

/// Opens [clip] in a large piano roll, with play/stop wired to [player].
///
/// Playback is the caller's own [onTogglePlay] — the same function the clip
/// row's play button calls — so the instrument, tempo and error handling are
/// exactly what the list uses. The playhead follows [player] for [playerKey],
/// converted to ticks at [bpm].
Future<void> showMidiPianoRoll(
  BuildContext context, {
  required MidiClip clip,
  required String title,
  String? subtitle,
  required MidiPreviewPlayer player,
  required String playerKey,
  required double bpm,
  required VoidCallback onTogglePlay,
}) {
  final l10n = AppLocalizations.of(context)!;
  final body = _PianoRollWindow(
    clip: clip,
    title: title,
    subtitle: subtitle,
    player: player,
    playerKey: playerKey,
    bpm: bpm,
    onTogglePlay: onTogglePlay,
    labels: MidiPianoRollLabels(
      zoomIn: l10n.midiPianoRollZoomIn,
      zoomOut: l10n.midiPianoRollZoomOut,
      fit: l10n.midiPianoRollFit,
      follow: l10n.midiPianoRollFollow,
    ),
    closeLabel: l10n.close,
    playLabel: l10n.midiClipPlay,
    stopLabel: l10n.midiClipStop,
  );
  return showDialog<void>(
    context: context,
    builder: (context) {
      if (MobileUtils.isMobile()) return Dialog.fullscreen(child: body);
      final size = MediaQuery.sizeOf(context);
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: size.width * 0.9,
          height: size.height * 0.85,
          child: body,
        ),
      );
    },
  );
}

class _PianoRollWindow extends StatelessWidget {
  const _PianoRollWindow({
    required this.clip,
    required this.title,
    required this.subtitle,
    required this.player,
    required this.playerKey,
    required this.bpm,
    required this.onTogglePlay,
    required this.labels,
    required this.closeLabel,
    required this.playLabel,
    required this.stopLabel,
  });

  final MidiClip clip;
  final String title;
  final String? subtitle;
  final MidiPreviewPlayer player;
  final String playerKey;
  final double bpm;
  final VoidCallback onTogglePlay;
  final MidiPianoRollLabels labels;
  final String closeLabel, playLabel, stopLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
                  final playing = player.playingKey == playerKey;
                  return IconButton(
                    tooltip: playing ? stopLabel : playLabel,
                    iconSize: 32,
                    icon: Icon(playing
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline),
                    onPressed: onTogglePlay,
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
              IconButton(
                tooltip: closeLabel,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: MidiPianoRoll(
              clip: clip,
              bpm: bpm,
              labels: labels,
              positionOf: () => player.positionOf(playerKey),
              playback: player,
            ),
          ),
        ],
      ),
    );
  }
}
