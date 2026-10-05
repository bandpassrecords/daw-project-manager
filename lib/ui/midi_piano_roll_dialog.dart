import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../utils/musical_scale.dart';
import '../services/midi/synth_voice.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_clip_edit_controller.dart';
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
  SynthVoice? voice,
  SaveEditedMidiClip? onSaveEdited,
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
    voice: voice,
    onSaveEdited: onSaveEdited,
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
        edit: l10n.midiEditNotes,
        undo: l10n.midiUndo,
        redo: l10n.midiRedo,
        deleteNote: l10n.midiDeleteNote,
        snap: l10n.midiSnap,
        snapOff: l10n.midiSnapOff,
        editHint: l10n.midiEditHint,
      ),
      close: l10n.close,
      play: l10n.midiClipPlay,
      pause: l10n.midiPianoRollPause,
      stop: l10n.midiClipStop,
      openProject: l10n.midiOpenSourceProject,
      saveAsNew: l10n.midiSaveAsNewClip,
      editedName: l10n.midiClipEditedName,
      discardTitle: l10n.midiDiscardEditsTitle,
      discardBody: l10n.midiDiscardEditsBody,
      keepEditing: l10n.midiKeepEditing,
      discard: l10n.midiDiscardEdits,
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
    // Sound with nothing on screen to stop it is the bug this prevents —
    // the clip as opened, or its edited version.
    final edited = MidiPianoRollWindow.editedKeyOf(playerKey);
    bool ours(String? k) => k == playerKey || k == edited;
    if (ours(player.playingKey) || ours(player.preparingKey)) player.stop();
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
    this.saveAsNew = '',
    this.editedName,
    this.discardTitle = '',
    this.discardBody = '',
    this.keepEditing = '',
    this.discard = '',
  });

  final MidiPianoRollLabels roll;
  final String close, play, pause, stop, openProject;

  /// Editing: the save button's tooltip, and the question asked before
  /// unsaved edits are thrown away.
  final String saveAsNew, discardTitle, discardBody, keepEditing, discard;

  /// The name an edited clip is saved under: "Riff (edited)".
  final String Function(String name)? editedName;
}

/// Saves a clip edited in the piano roll — as a new clip; the one opened is
/// never changed — with the key it was being edited in. Resolves to whether
/// it was saved (false: the user backed out, of a collection picker say).
typedef SaveEditedMidiClip = Future<bool> Function(
    MidiClip clip, String? musicalKey);

/// The contents of [showMidiPianoRoll]'s window — public so it can be tested
/// without a dialog route around it.
///
/// Given [onSaveEdited], the window is also an editor: the piano roll gets
/// its edit tools (see [MidiClipEditController]), Delete and Ctrl/Cmd+Z,
/// Ctrl/Cmd+Shift+Z (or Ctrl+Y) work, play plays the edited clip, a Save
/// button saves it as a new clip, and closing with unsaved edits asks
/// first.
class MidiPianoRollWindow extends StatefulWidget {
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
    this.voice,
    this.onSaveEdited,
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
        voice: base.voice,
        onSaveEdited: base.onSaveEdited,
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

  /// The instrument an edited clip plays with; null infers one from it.
  final SynthVoice? voice;

  /// Makes the window an editor, saving edits through it. Null: view only.
  final SaveEditedMidiClip? onSaveEdited;

  final MidiClip clip;
  final String title;
  final String? subtitle;
  final MidiPreviewPlayer player;
  final String playerKey;
  final double bpm;
  final VoidCallback onPlay;
  final VoidCallback? onOpenProject;
  final MidiPianoRollWindowLabels labels;

  /// The player key the edited version of [playerKey]'s clip plays under.
  static String editedKeyOf(String playerKey) => '$playerKey~edit';

  @override
  State<MidiPianoRollWindow> createState() => _MidiPianoRollWindowState();
}

class _MidiPianoRollWindowState extends State<MidiPianoRollWindow> {
  late final MidiClipEditController? _editor = widget.onSaveEdited == null
      ? null
      : MidiClipEditController(widget.clip);

  /// The scale being edited in — what a saved clip keeps as its key.
  late MusicalScale? _scale = scaleFromKey(widget.musicalKey);

  /// The edited clip last handed to the player, to replay after a change.
  MidiClip? _playedEdit;

  /// Set once the user agreed to throw unsaved edits away.
  bool _leaving = false;

  MidiPreviewPlayer get _player => widget.player;
  MidiPianoRollWindowLabels get labels => widget.labels;
  String get _editKey => MidiPianoRollWindow.editedKeyOf(widget.playerKey);

  /// Whether what is on screen differs from the clip opened — then play
  /// plays it, saved or not.
  bool get _differs =>
      _editor != null && !identical(_editor.committed, widget.clip);

  /// Unsaved edits: what the save button and the close prompt are about.
  bool get _unsaved => _editor?.edited ?? false;

  /// Whether the player is busy with this window's clip, either version.
  bool get _isOurs {
    final k = _player.playingKey;
    return k == widget.playerKey || k == _editKey;
  }

  bool get _preparing {
    final k = _player.preparingKey;
    return k == widget.playerKey || k == _editKey;
  }

  @override
  void initState() {
    super.initState();
    _editor?.addListener(_onEdit);
  }

  @override
  void dispose() {
    _editor?.removeListener(_onEdit);
    _editor?.dispose();
    super.dispose();
  }

  void _onEdit() {
    if (!mounted) return;
    setState(() {});
    // A finished edit while the edited clip plays: carry on with the new
    // notes from where it was.
    final editor = _editor!;
    if (_player.playingKey != _editKey || _player.paused) return;
    if (identical(_playedEdit, editor.committed)) return;
    _playEdited(from: _player.positionOf(_editKey));
  }

  void _playEdited({Duration? from}) {
    final editor = _editor!;
    _playedEdit = editor.committed;
    final clip = editor.finished;
    if (from != null) _player.startAt(_editKey, from);
    _player
        .play(_editKey, clip,
            bpm: widget.bpm, voice: widget.voice ?? inferSynthVoice(clip))
        .catchError((Object _) {});
  }

  void _start() => _differs ? _playEdited() : widget.onPlay();

  /// The ruler was clicked: jump there, or — with this clip not playing —
  /// start playback from there.
  void _seek(Duration position) {
    final playing = _player.playingKey;
    if (_isOurs && playing != null) {
      _player.seek(playing, position);
    } else if (_differs) {
      _playEdited(from: position);
    } else {
      _player.startAt(widget.playerKey, position);
      widget.onPlay();
    }
  }

  /// Esc: stop this clip if it is playing (or paused, or still rendering),
  /// otherwise close the window.
  void _escape() {
    if (_isOurs || _preparing) {
      _player.stop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Space: start, pause, or resume.
  void _playPause() {
    if (!_isOurs) {
      _start();
    } else if (_player.paused) {
      _player.resume();
    } else {
      _player.pause();
    }
  }

  Future<void> _save() async {
    final editor = _editor;
    final save = widget.onSaveEdited;
    if (editor == null || save == null) return;
    final name = labels.editedName?.call(widget.clip.name) ?? widget.clip.name;
    final saved = await save(
      editor.finished.copyWith(name: name),
      _scale?.keyText ?? widget.musicalKey,
    );
    if (saved && mounted) editor.markSaved();
  }

  /// Asks before unsaved edits are thrown away. True: go ahead.
  Future<bool> _confirmDiscard() async {
    if (!_unsaved || _leaving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels.discardTitle),
        content: Text(labels.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(labels.discard),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return false;
    setState(() => _leaving = true);
    return true;
  }

  Future<void> _close() async {
    if (!await _confirmDiscard() || !mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editor = _editor;
    return PopScope(
      // Esc, the barrier and the back button all come through here.
      canPop: !_unsaved || _leaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _playPause,
          const SingleActivator(LogicalKeyboardKey.escape): _escape,
          if (editor != null) ...{
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (editor.editing) editor.deleteSelected();
            },
            const SingleActivator(LogicalKeyboardKey.backspace): () {
              if (editor.editing) editor.deleteSelected();
            },
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                editor.undo,
            const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
                editor.undo,
            const SingleActivator(LogicalKeyboardKey.keyZ,
                control: true, shift: true): editor.redo,
            const SingleActivator(LogicalKeyboardKey.keyZ,
                meta: true, shift: true): editor.redo,
            const SingleActivator(LogicalKeyboardKey.keyY, control: true):
                editor.redo,
            // As in Cubase: ↑/↓ a semitone, Shift+↑/↓ an octave.
            const SingleActivator(LogicalKeyboardKey.arrowUp): () {
              if (editor.editing) editor.transposeSelection(1);
            },
            const SingleActivator(LogicalKeyboardKey.arrowDown): () {
              if (editor.editing) editor.transposeSelection(-1);
            },
            const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
                () {
              if (editor.editing) editor.transposeSelection(12);
            },
            const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
                () {
              if (editor.editing) editor.transposeSelection(-12);
            },
            const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
              if (editor.editing) editor.selectAll();
            },
            const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () {
              if (editor.editing) editor.selectAll();
            },
          },
        },
        // Autofocus so Space works the moment the window opens, before
        // anything inside it has been clicked.
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
                    clip: widget.clip,
                    editor: editor,
                    bpm: widget.bpm,
                    labels: labels.roll,
                    positionOf: () {
                      final k = _player.playingKey;
                      return k != null && _isOurs ? _player.positionOf(k) : null;
                    },
                    playback: _player,
                    onSeek: _seek,
                    initialScale: scaleFromKey(widget.musicalKey),
                    onScaleChanged: (s) => _scale = s,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The window's top: transport, title, loop, volume, save, open project,
  /// close. Stacked on a narrow screen — the title on a line of its own, up
  /// to two lines long, the controls in a row beneath — because squeezed
  /// into one row with everything else a phone left the name a few letters
  /// wide.
  Widget _header(BuildContext context, {required bool stacked}) {
    final theme = Theme.of(context);
    final transport = ListenableBuilder(
      listenable: _player,
      builder: (context, _) {
        if (_preparing) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final running = _isOurs && !_player.paused;
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
                onPressed: _player.stop,
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
        Text(widget.title,
            key: const ValueKey('midi-piano-roll-title'),
            style: theme.textTheme.titleMedium,
            maxLines: lines,
            overflow: TextOverflow.ellipsis),
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
          Text(widget.subtitle!,
              style: theme.textTheme.bodySmall,
              maxLines: lines,
              overflow: TextOverflow.ellipsis),
      ],
    );
    final controls = <Widget>[
      if (widget.loop != null &&
          widget.onLoopChanged != null &&
          widget.loopTooltip != null)
        MidiLoopToggle(
          loop: widget.loop!,
          onChanged: widget.onLoopChanged!,
          tooltip: widget.loopTooltip!,
        ),
      if (widget.volume != null &&
          widget.onVolumeChanged != null &&
          widget.volumeLabels != null)
        MidiVolumeControl(
          volume: widget.volume!,
          onChanged: widget.onVolumeChanged!,
          labels: widget.volumeLabels!,
          sliderWidth: 90,
        ),
      if (_unsaved)
        IconButton(
          key: const ValueKey('midi-piano-roll-save'),
          tooltip: labels.saveAsNew,
          icon: const Icon(Icons.save_as_outlined),
          color: theme.colorScheme.primary,
          onPressed: _save,
        ),
      if (widget.onOpenProject != null)
        IconButton(
          tooltip: labels.openProject,
          icon: const Icon(Icons.assignment),
          onPressed: () async {
            if (!await _confirmDiscard() || !context.mounted) return;
            _player.stop();
            Navigator.of(context).pop();
            widget.onOpenProject!();
          },
        ),
    ];
    final close = IconButton(
      tooltip: labels.close,
      icon: const Icon(Icons.close),
      onPressed: _close,
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
