import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../utils/musical_scale.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_piano_roll.dart';
import 'widgets/midi_loop_toggle.dart';
import 'widgets/midi_volume_control.dart';

/// Opens [clip] in a large piano roll, with transport wired to [player].
///
/// Starting playback is the caller's own [onPlay] — the same function the
/// clip row's play button calls — so the instrument, tempo and error
/// handling are exactly what the list uses; pause, resume and stop go to
/// [player] directly. Space plays and pauses; clicking the bar ruler jumps
/// playback there, or starts it from there when stopped. Esc stops the
/// clip, or closes the window when nothing is playing — and however the
/// window closes, the clip it was playing stops with it.
///
/// [onOpenProject] adds its button when given. Opening the project closes
/// this window and stops the preview first.
Future<void> showMidiPianoRoll(
  BuildContext context, {
  required MidiClip clip,
  required String title,
  String? subtitle,
  required MidiPreviewPlayer player,
  required String playerKey,
  required double bpm,
  required VoidCallback onPlay,
  VoidCallback? onOpenProject,
  String? musicalKey,
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
    onOpenProject: onOpenProject,
    musicalKey: musicalKey,
    labels: MidiPianoRollWindowLabels(
      roll: MidiPianoRollLabels(
        zoomIn: l10n.midiPianoRollZoomIn,
        zoomOut: l10n.midiPianoRollZoomOut,
        fit: l10n.midiPianoRollFit,
        follow: l10n.midiPianoRollFollow,
        lane: l10n.midiLanePicker,
        laneNone: l10n.midiLaneNone,
        laneName: (lane) => midiLaneName(l10n, lane),
        scale: l10n.midiScale,
        scaleNone: l10n.midiScaleNone,
        scaleRoot: l10n.midiScaleRoot,
        scaleType: l10n.midiScaleType,
        scaleTypeName: (type) => scaleTypeName(l10n, type),
      ),
      close: l10n.close,
      play: l10n.midiClipPlay,
      pause: l10n.midiPianoRollPause,
      stop: l10n.midiClipStop,
      openProject: l10n.midiOpenSourceProject,
    ),
  );
  // The shared preview volume and loop setting, live: the window's controls
  // and the list's move together, and either one changes what is playing.
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
        loop: ref.watch(midiPreviewLoopProvider),
        onLoopChanged: (v) {
          ref.read(midiPreviewLoopProvider.notifier).set(v);
          player.setLoop(v);
        },
        loopTooltip: l10n.midiPreviewLoop,
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
  ).whenComplete(() {
    // Sound with nothing on screen to stop it is the bug this prevents.
    if (player.playingKey == playerKey || player.preparingKey == playerKey) {
      player.stop();
    }
  });
}

/// A lane's name in the piano roll's picker: "Velocity", "Pitch bend",
/// "CC 1 · Modulation", "CC 20"…
String midiLaneName(AppLocalizations l10n, MidiLane lane) {
  final kind = lane.kind;
  if (kind == null) return l10n.midiLaneVelocity;
  return switch (kind) {
    MidiEventKind.pitchBend => l10n.midiLanePitchBend,
    MidiEventKind.channelPressure => l10n.midiLaneChannelPressure,
    MidiEventKind.polyPressure => l10n.midiLanePolyPressure,
    MidiEventKind.program => l10n.midiLaneProgram,
    MidiEventKind.controller => switch (_controllerName(l10n, lane.number)) {
        final name? => l10n.midiLaneControllerNamed(lane.number, name),
        null => l10n.midiLaneController(lane.number),
      },
  };
}

/// The usual name of controller [number], for the ones every DAW names.
String? _controllerName(AppLocalizations l10n, int number) => switch (number) {
      1 => l10n.midiCcModulation,
      2 => l10n.midiCcBreath,
      4 => l10n.midiCcFoot,
      5 => l10n.midiCcPortamentoTime,
      7 => l10n.midiCcVolume,
      8 => l10n.midiCcBalance,
      10 => l10n.midiCcPan,
      11 => l10n.midiCcExpression,
      64 => l10n.midiCcSustain,
      65 => l10n.midiCcPortamento,
      66 => l10n.midiCcSostenuto,
      67 => l10n.midiCcSoftPedal,
      71 => l10n.midiCcResonance,
      72 => l10n.midiCcRelease,
      73 => l10n.midiCcAttack,
      74 => l10n.midiCcCutoff,
      91 => l10n.midiCcReverb,
      93 => l10n.midiCcChorus,
      _ => null,
    };

/// A scale type's name in the piano roll's scale chooser.
String scaleTypeName(AppLocalizations l10n, ScaleType type) => switch (type) {
      ScaleType.major => l10n.scaleMajor,
      ScaleType.minor => l10n.scaleMinor,
      ScaleType.harmonicMinor => l10n.scaleHarmonicMinor,
      ScaleType.melodicMinor => l10n.scaleMelodicMinor,
      ScaleType.dorian => l10n.scaleDorian,
      ScaleType.phrygian => l10n.scalePhrygian,
      ScaleType.lydian => l10n.scaleLydian,
      ScaleType.mixolydian => l10n.scaleMixolydian,
      ScaleType.locrian => l10n.scaleLocrian,
      ScaleType.majorPentatonic => l10n.scaleMajorPentatonic,
      ScaleType.minorPentatonic => l10n.scaleMinorPentatonic,
      ScaleType.blues => l10n.scaleBlues,
    };

class MidiPianoRollWindowLabels {
  const MidiPianoRollWindowLabels({
    required this.roll,
    required this.close,
    required this.play,
    required this.pause,
    required this.stop,
    required this.openProject,
  });

  final MidiPianoRollLabels roll;
  final String close, play, pause, stop, openProject;
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
    this.onOpenProject,
    this.volume,
    this.onVolumeChanged,
    this.volumeLabels,
    this.loop,
    this.onLoopChanged,
    this.loopTooltip,
    this.musicalKey,
  });

  /// [base] with a volume control added.
  factory MidiPianoRollWindow.copyOf(
    MidiPianoRollWindow base, {
    required double volume,
    required ValueChanged<double> onVolumeChanged,
    required MidiVolumeLabels volumeLabels,
    bool? loop,
    ValueChanged<bool>? onLoopChanged,
    String? loopTooltip,
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
        onOpenProject: base.onOpenProject,
        volume: volume,
        onVolumeChanged: onVolumeChanged,
        volumeLabels: volumeLabels,
        loop: loop,
        onLoopChanged: onLoopChanged,
        loopTooltip: loopTooltip,
        musicalKey: base.musicalKey,
      );

  /// The shared preview volume; the control shows only when all three of
  /// [volume], [onVolumeChanged] and [volumeLabels] are given.
  final double? volume;
  final ValueChanged<double>? onVolumeChanged;
  final MidiVolumeLabels? volumeLabels;

  /// The shared loop setting; the toggle shows only when all three of
  /// [loop], [onLoopChanged] and [loopTooltip] are given.
  final bool? loop;
  final ValueChanged<bool>? onLoopChanged;
  final String? loopTooltip;

  /// The source project's key: the scale the piano roll opens with.
  final String? musicalKey;

  final MidiClip clip;
  final String title;
  final String? subtitle;
  final MidiPreviewPlayer player;
  final String playerKey;
  final double bpm;
  final VoidCallback onPlay;
  final VoidCallback? onOpenProject;
  final MidiPianoRollWindowLabels labels;

  bool get _isOurs => player.playingKey == playerKey;

  /// The ruler was clicked: jump there, or — with this clip not playing —
  /// start playback from there.
  void _seek(Duration position) {
    if (_isOurs) {
      player.seek(playerKey, position);
    } else {
      player.startAt(playerKey, position);
      onPlay();
    }
  }

  /// Esc: stop this clip if it is playing (or paused, or still rendering),
  /// otherwise close the window.
  void _escape(BuildContext context) {
    if (_isOurs || player.preparingKey == playerKey) {
      player.stop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _playPause,
        const SingleActivator(LogicalKeyboardKey.escape): () => _escape(context),
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
              LayoutBuilder(
                builder: (context, constraints) => _header(
                  context,
                  stacked: pianoRollHeaderStacked(constraints.maxWidth),
                ),
              ),
              Expanded(
                child: MidiPianoRoll(
                  clip: clip,
                  bpm: bpm,
                  labels: labels.roll,
                  positionOf: () => player.positionOf(playerKey),
                  playback: player,
                  onSeek: _seek,
                  initialScale: scaleFromKey(musicalKey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The window's top: transport, title, loop, volume, open project, close.
  /// Stacked on a narrow screen — the title on a line of its own, up to two
  /// lines long, the controls in a row beneath — because squeezed into one
  /// row with everything else a phone left the name a few letters wide.
  Widget _header(BuildContext context, {required bool stacked}) {
    final theme = Theme.of(context);
    final transport = ListenableBuilder(
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
                  );
    final lines = stacked ? 2 : 1;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            key: const ValueKey('midi-piano-roll-title'),
            style: theme.textTheme.titleMedium,
            maxLines: lines,
            overflow: TextOverflow.ellipsis),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(subtitle!,
              style: theme.textTheme.bodySmall,
              maxLines: lines,
              overflow: TextOverflow.ellipsis),
      ],
    );
    final controls = <Widget>[
      if (loop != null && onLoopChanged != null && loopTooltip != null)
        MidiLoopToggle(
          loop: loop!,
          onChanged: onLoopChanged!,
          tooltip: loopTooltip!,
        ),
      if (volume != null && onVolumeChanged != null && volumeLabels != null)
        MidiVolumeControl(
          volume: volume!,
          onChanged: onVolumeChanged!,
          labels: volumeLabels!,
          sliderWidth: 90,
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
    ];
    final close = IconButton(
      tooltip: labels.close,
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    );

    if (!stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          transport,
          const SizedBox(width: 8),
          Expanded(child: titleBlock),
          ...controls,
          close,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            Expanded(child: titleBlock),
            close,
          ],
        ),
        // Scrolls sideways rather than overflow on the narrowest phones.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [transport, ...controls],
          ),
        ),
      ],
    );
  }
}

/// Whether the piano roll window's header stacks its title above the
/// controls: below this width a single row leaves the clip's name a few
/// letters wide.
bool pianoRollHeaderStacked(double width) => width < 600;
