import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../providers/providers.dart';
import '../services/midi_editor_prefs_store.dart';
import '../utils/mobile_utils.dart';
import '../utils/musical_scale.dart';
import '../utils/time_signature.dart';
import '../services/midi/synth_voice.dart';
import 'midi_note_auditioner.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_clip_edit_controller.dart';
import 'widgets/midi_clip_list.dart';
import 'widgets/midi_clips_section.dart' show midiTempoLabelsOf, synthVoiceName;
import 'widgets/midi_tempo_control.dart';
import 'widgets/midi_piano_roll.dart';
import 'widgets/midi_shortcuts_sheet.dart';
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
///
/// The instrument can be changed from the window; [onVoiceChanged] tells
/// the list it was opened from, so the clip keeps it there too.
Future<void> showMidiPianoRoll(
  BuildContext context, {
  required MidiClip clip,
  required String title,
  String? subtitle,
  required MidiPreviewPlayer player,
  required String playerKey,
  required double bpm,
  required void Function(SynthVoice voice, double bpm) onPlay,
  VoidCallback? onOpenProject,
  String? musicalKey,
  TimeSignature timeSignature = TimeSignature.common,
  SynthVoice? voice,
  ValueChanged<SynthVoice>? onVoiceChanged,
  SaveEditedMidiClip? onSaveEdited,
  bool startEditing = false,
  bool lengthFollowsNotes = false,
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
    onVoiceChanged: onVoiceChanged,
    onSaveEdited: onSaveEdited,
    startEditing: startEditing,
    lengthFollowsNotes: lengthFollowsNotes,
    timeSignature: timeSignature,
    // A phone has no keys to press; its gestures are the plain ones.
    onShowShortcuts: MobileUtils.isMobile()
        ? null
        : () => showDialog<void>(
              context: context,
              builder: (_) => MidiShortcutsSheet(
                title: l10n.midiShortcutsTitle,
                close: l10n.close,
                sections: midiShortcutSections(l10n,
                    mac: defaultTargetPlatform == TargetPlatform.macOS),
              ),
            ),
    acousticFeedback: MidiAcousticFeedbackStore.current,
    onAcousticFeedbackChanged: MidiAcousticFeedbackStore.save,
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
        snap: l10n.midiSnap,
        snapOff: l10n.midiSnapOff,
        toolSelect: l10n.midiToolSelect,
        toolRange: l10n.midiToolRange,
        toolEraser: l10n.midiToolEraser,
        toolPencil: l10n.midiToolPencil,
        duplicate: l10n.midiDuplicate,
        quantize: l10n.midiQuantize,
        transpose: l10n.midiTranspose,
        transposeUpSemitone: l10n.midiTransposeUpSemitone,
        transposeDownSemitone: l10n.midiTransposeDownSemitone,
        transposeUpOctave: l10n.midiTransposeUpOctave,
        transposeDownOctave: l10n.midiTransposeDownOctave,
        acousticFeedback: l10n.midiAcousticFeedback,
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
      voiceName: (v) => synthVoiceName(l10n, v),
      instrument: l10n.midiClipInstrumentTooltip,
      tempo: midiTempoLabelsOf(l10n),
      timeSignature: l10n.midiTimeSignature,
      shortcuts: l10n.midiShortcuts,
      fullScreen: l10n.midiFullScreen,
      exitFullScreen: l10n.midiExitFullScreen,
    ),
  );
  final mobile = MobileUtils.isMobile();
  // The whole app window, or a large dialog in it — remembered on this
  // device. A phone always has the whole screen.
  final fullScreen = ValueNotifier(MidiPianoRollFullScreenStore.current);
  // The shared preview volume and loop setting, live: the window's controls
  // and the list's move together, and either one changes what is playing.
  Widget content(bool full) => Consumer(
    builder: (context, ref, _) {
      final volume = ref.watch(midiPreviewVolumeProvider);
      return MidiPianoRollWindow.copyOf(
        body,
        fullScreen: mobile ? null : full,
        onFullScreenChanged: mobile
            ? null
            : (v) {
                fullScreen.value = v;
                MidiPianoRollFullScreenStore.save(v);
              },
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
      if (mobile) return Dialog.fullscreen(child: content(true));
      // One Dialog either way — only its insets and size change — so
      // switching keeps the window's state, unsaved edits included.
      return ValueListenableBuilder<bool>(
        valueListenable: fullScreen,
        builder: (context, full, _) {
          final size = MediaQuery.sizeOf(context);
          return Dialog(
            insetPadding: full ? EdgeInsets.zero : const EdgeInsets.all(24),
            shape: full ? const RoundedRectangleBorder() : null,
            child: SizedBox(
              width: full ? size.width : size.width * 0.9,
              height: full ? size.height : size.height * 0.85,
              child: content(full),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    fullScreen.dispose();
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

/// Every shortcut and gesture of the piano roll, for its sheet. Keys are
/// named the way this platform's keyboard prints them ([mac]: ⌘ ⌥ ⇧ ⌫).
List<MidiShortcutSection> midiShortcutSections(
  AppLocalizations l10n, {
  required bool mac,
}) {
  final ctrl = mac ? '⌘' : l10n.midiKeyCtrl;
  final alt = mac ? '⌥' : l10n.midiKeyAlt;
  final shift = mac ? '⇧' : l10n.midiKeyShift;
  final delete = mac ? '⌫' : l10n.midiKeyDelete;
  final click = l10n.midiGestureClick;
  final drag = l10n.midiGestureDrag;
  const arrows = '↑ / ↓';
  return [
    MidiShortcutSection(l10n.midiShortcutsTools, [
      MidiShortcut(const ['1'], l10n.midiShortcutSelectTool),
      MidiShortcut(const ['2'], l10n.midiShortcutRangeTool),
      MidiShortcut(const ['5'], l10n.midiShortcutEraserTool),
      MidiShortcut(const ['8'], l10n.midiShortcutPencilTool),
    ]),
    MidiShortcutSection(l10n.midiShortcutsNotes, [
      MidiShortcut([l10n.midiGestureDoubleClick], l10n.midiShortcutDoubleClick),
      MidiShortcut([drag], l10n.midiShortcutMove),
      MidiShortcut([drag], l10n.midiShortcutResize),
      MidiShortcut([alt, drag], l10n.midiShortcutCopy),
      MidiShortcut([ctrl, drag], l10n.midiShortcutOffGrid),
      MidiShortcut(const [arrows], l10n.midiShortcutSemitone),
      MidiShortcut([shift, arrows], l10n.midiShortcutOctave),
      MidiShortcut([ctrl, 'D'], l10n.midiShortcutDuplicate),
      MidiShortcut(const ['Q'], l10n.midiShortcutQuantize),
      MidiShortcut([delete], l10n.midiShortcutDelete),
    ]),
    MidiShortcutSection(l10n.midiShortcutsSelecting, [
      MidiShortcut([drag], l10n.midiShortcutBox),
      MidiShortcut(['$ctrl / $shift', click], l10n.midiShortcutToggle),
      MidiShortcut([ctrl, 'A'], l10n.midiShortcutSelectAll),
    ]),
    MidiShortcutSection(l10n.midiShortcutsLanes, [
      MidiShortcut([drag], l10n.midiShortcutVelocity),
      MidiShortcut([drag], l10n.midiShortcutLane),
    ]),
    MidiShortcutSection(l10n.midiShortcutsEditing, [
      MidiShortcut([ctrl, 'Z'], l10n.midiUndo),
      MidiShortcut([ctrl, shift, 'Z'], l10n.midiRedo),
    ]),
    MidiShortcutSection(l10n.midiShortcutsPlayback, [
      MidiShortcut([l10n.midiKeySpace], l10n.midiShortcutPlay),
      MidiShortcut([l10n.midiKeyEsc], l10n.midiShortcutStop),
      MidiShortcut([click], l10n.midiShortcutKeyboard),
      MidiShortcut([click], l10n.midiShortcutRuler),
      MidiShortcut([ctrl, click], l10n.midiShortcutLoopStart),
      MidiShortcut([alt, click], l10n.midiShortcutLoopEnd),
      MidiShortcut([drag], l10n.midiShortcutLoopDrag),
      MidiShortcut([click], l10n.midiShortcutLoopToggle),
      MidiShortcut([ctrl, l10n.midiGestureWheel], l10n.midiShortcutZoom),
      MidiShortcut([shift, l10n.midiGestureWheel], l10n.midiShortcutScroll),
      MidiShortcut(const ['?'], l10n.midiShortcutShowSheet),
    ]),
  ];
}

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
    this.voiceName,
    this.instrument,
    this.shortcuts = '',
    this.tempo,
    this.timeSignature = '',
    this.fullScreen = '',
    this.exitFullScreen = '',
  });

  /// The shortcut sheet button's tooltip.
  final String shortcuts;

  /// The tempo control's strings; it shows when given.
  final MidiTempoLabels? tempo;

  /// The time signature picker's tooltip; it shows when given.
  final String timeSignature;

  /// The full screen toggle's tooltips.
  final String fullScreen, exitFullScreen;

  final MidiPianoRollLabels roll;

  /// The instrument picker's voice names and tooltip ("Instrument: Bass");
  /// the picker shows when both are given.
  final String Function(SynthVoice voice)? voiceName;
  final String Function(String name)? instrument;
  final String close, play, pause, stop, openProject;

  /// Editing: the save button's tooltip, and the question asked before
  /// unsaved edits are thrown away.
  final String saveAsNew, discardTitle, discardBody, keepEditing, discard;

  /// The name an edited clip is saved under: "Riff (edited)".
  final String Function(String name)? editedName;
}

/// What the piano roll window hands over to be saved: the edited clip, and
/// how it was being heard — the scale as a key, the instrument, the tempo
/// and the time signature.
class EditedMidiClip {
  const EditedMidiClip({
    required this.clip,
    required this.voice,
    required this.bpm,
    this.musicalKey,
    this.timeSignature = TimeSignature.common,
  });

  final MidiClip clip;
  final String? musicalKey;
  final SynthVoice voice;
  final double bpm;
  final TimeSignature timeSignature;
}

/// Saves a clip edited in the piano roll — as a new clip; the one opened is
/// never changed. Resolves to whether it was saved (false: the user backed
/// out, of a collection picker say).
typedef SaveEditedMidiClip = Future<bool> Function(EditedMidiClip edit);

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
    this.onVoiceChanged,
    this.onSaveEdited,
    this.onShowShortcuts,
    this.acousticFeedback = false,
    this.onAcousticFeedbackChanged,
    this.auditioner,
    this.startEditing = false,
    this.lengthFollowsNotes = false,
    this.timeSignature = TimeSignature.common,
    this.fullScreen,
    this.onFullScreenChanged,
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
    bool? fullScreen,
    ValueChanged<bool>? onFullScreenChanged,
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
        onVoiceChanged: base.onVoiceChanged,
        onSaveEdited: base.onSaveEdited,
        onShowShortcuts: base.onShowShortcuts,
        acousticFeedback: base.acousticFeedback,
        onAcousticFeedbackChanged: base.onAcousticFeedbackChanged,
        auditioner: base.auditioner,
        startEditing: base.startEditing,
        lengthFollowsNotes: base.lengthFollowsNotes,
        timeSignature: base.timeSignature,
        fullScreen: fullScreen,
        onFullScreenChanged: onFullScreenChanged,
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

  /// The instrument the clip plays with; null infers one from it.
  final SynthVoice? voice;

  /// Told when the instrument is changed in the window.
  final ValueChanged<SynthVoice>? onVoiceChanged;

  /// Whether the window fills the whole app window; the toggle shows when
  /// both this and [onFullScreenChanged] are given (not on a phone, where
  /// it always does).
  final bool? fullScreen;
  final ValueChanged<bool>? onFullScreenChanged;

  /// Opens the sheet of every shortcut and gesture (also on `?` and F1);
  /// null leaves its button out.
  final VoidCallback? onShowShortcuts;

  /// Whether notes sound as they are edited, and where to remember it.
  final bool acousticFeedback;
  final ValueChanged<bool>? onAcousticFeedbackChanged;

  /// Sounds keys and edited notes; the window makes its own when null.
  final MidiNoteAuditioner? auditioner;

  /// Opens already editing, pencil in hand — for a blank clip to draft in.
  final bool startEditing;

  /// A clip drafted from nothing: its length follows its notes, shrinking
  /// too (see [MidiClipEditController.lengthFollowsNotes]).
  final bool lengthFollowsNotes;

  /// The bars the clip opens in; changeable in the window.
  final TimeSignature timeSignature;

  /// Makes the window an editor, saving edits through it. Null: view only.
  final SaveEditedMidiClip? onSaveEdited;

  final MidiClip clip;
  final String title;
  final String? subtitle;
  final MidiPreviewPlayer player;
  final String playerKey;
  final double bpm;

  /// Plays the clip as opened with the given instrument and tempo — the
  /// list's own play, so error handling matches it.
  final void Function(SynthVoice voice, double bpm) onPlay;
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

  /// Where the window's keys are listened for — what a text field gives the
  /// keyboard back to.
  final FocusNode _keys = FocusNode(debugLabel: 'midi-piano-roll-keys');

  /// A field let go of the keyboard (Enter in the tempo does) and it fell
  /// back to the window's own route: the window's keys take it, or no
  /// shortcut would work until something was clicked. Focus that went
  /// anywhere else — a dialog over this one — is left alone.
  void _reclaimKeys() {
    final primary = FocusManager.instance.primaryFocus;
    if (!mounted || primary == null || primary == _keys) return;
    if (_keys.ancestors.contains(primary)) _keys.requestFocus();
  }

  /// The instrument both versions of the clip play with.
  late SynthVoice _voice = widget.voice ?? inferSynthVoice(widget.clip);

  /// The tempo both versions play at, and the bars they're drawn in.
  late double _bpm = widget.bpm;
  late TimeSignature _timeSignature = widget.timeSignature;

  late bool _feedback = widget.acousticFeedback;

  MidiNoteAuditioner? _ownAuditioner;
  MidiNoteAuditioner get _auditioner =>
      widget.auditioner ?? (_ownAuditioner ??= MidiNoteAuditioner());

  /// Sounds one note in the clip's instrument, at the preview volume.
  void _audition(int pitch, int velocity) {
    _auditioner
      ..voice = _voice
      ..volume = widget.volume ?? _player.volume;
    _auditioner.play(pitch, velocity: velocity);
  }

  /// A new instrument: the list hears of it, and a clip playing carries on
  /// from where it is with it (a paused one starts there next time).
  void _setVoice(SynthVoice voice) {
    if (voice == _voice) return;
    _restartWith(() => _voice = voice);
    widget.onVoiceChanged?.call(voice);
  }

  /// A new tempo: playback carries on from the same spot in the music —
  /// the same tick, at the new speed.
  void _setBpm(double bpm) {
    if (bpm == _bpm) return;
    final old = _bpm;
    final ppq = widget.clip.ppq;
    _restartWith(
      () => _bpm = bpm,
      at: (position) => durationAtTick(ticksAt(position, old, ppq), bpm, ppq),
    );
  }

  void _setTimeSignature(TimeSignature value) {
    if (value == _timeSignature) return;
    setState(() => _timeSignature = value);
    _editor?.timeSignature = value;
  }

  /// Applies [change]; a clip playing here (or paused) then starts again
  /// with it, from where it was — [at] moves that spot, for a new tempo.
  void _restartWith(VoidCallback change, {Duration Function(Duration)? at}) {
    final key = _player.playingKey;
    final position = key != null && _isOurs ? _player.positionOf(key) : null;
    final running = position != null && !_player.paused;
    setState(change);
    if (key == null || position == null) return;
    _player.stop();
    _player.startAt(key, at == null ? position : at(position));
    if (!running) return;
    if (key == _editKey || _activeRegion != null || widget.lengthFollowsNotes) {
      _playHere();
    } else {
      _playingRegion = null;
      widget.onPlay(_voice, _bpm);
    }
  }

  /// ↑/↓ (Shift: an octave), sounding the moved notes with feedback on.
  void _transpose(MidiClipEditController editor, int semitones) {
    if (!editor.editing || editor.selection.isEmpty) return;
    editor.transposeSelection(semitones);
    if (!_feedback) return;
    for (final i in editor.selection.take(4)) {
      final n = editor.clip.notes[i];
      _audition(n.pitch, n.velocity);
    }
  }

  void _setTool(MidiClipEditController editor, MidiEditTool tool) {
    if (editor.editing) editor.tool = tool;
  }

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
    _editor?.timeSignature = _timeSignature;
    _editor?.lengthFollowsNotes = widget.lengthFollowsNotes;
    if (widget.startEditing && _editor != null) {
      _editor
        ..editing = true
        ..tool = MidiEditTool.pencil;
    }
    _editor?.addListener(_onEdit);
    FocusManager.instance.addListener(_reclaimKeys);
  }

  @override
  void dispose() {
    _editor?.removeListener(_onEdit);
    _editor?.dispose();
    _ownAuditioner?.dispose();
    FocusManager.instance.removeListener(_reclaimKeys);
    _keys.dispose();
    _horizonTimer?.cancel();
    _regionRestart?.cancel();
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
    _playHere(takeOver: true);
  }

  /// The loop region (Cubase's locators), set on the ruler. With looping on,
  /// playback cycles just this stretch. A clip with a length of its own
  /// opens with it spanning that length; a clip drafted from nothing opens
  /// with none (nothing bounds it while it is drawn), and gets one up to
  /// the end of its last bar with notes once it is saved.
  late MidiTickRange? _loopRegion =
      widget.lengthFollowsNotes || widget.clip.lengthTicks <= 0
          ? null
          : (start: 0, end: widget.clip.lengthTicks);

  /// The region the playing preview was cut to, if it was: positions in it
  /// are offset by its start in the whole clip.
  MidiTickRange? _playingRegion;

  /// The loop region playback goes by: only with looping on.
  MidiTickRange? get _activeRegion =>
      (widget.loop ?? false) ? _loopRegion : null;

  int get _ppq => widget.clip.ppq;

  /// [position] in a preview cut to [from] (null: the whole clip), as the
  /// same spot in one cut to [to] — the loop's start when it's outside it.
  Duration _between(Duration position, MidiTickRange? from, MidiTickRange? to) {
    var tick = ticksAt(position, _bpm, _ppq) + (from?.start ?? 0);
    if (to != null) {
      tick = tick >= to.start && tick < to.end ? tick - to.start : 0;
    }
    return durationAtTick(tick, _bpm, _ppq);
  }

  /// Plays from the window itself: the edited clip when there is one, cut to
  /// the loop region when looping in one. [takeOver] swaps it in for what
  /// plays without a gap (see [MidiPreviewPlayer.play]).
  void _playHere({Duration? from, bool takeOver = false}) {
    final key = _differs ? _editKey : widget.playerKey;
    var clip = _differs ? _editor!.finished : widget.clip;
    if (_differs) _playedEdit = _editor!.committed;
    final region = _activeRegion;
    _playingRegion = region;
    final openEnded = region == null && widget.lengthFollowsNotes;
    if (region != null) {
      clip = loopRegionClip(clip, region);
    } else if (openEnded) {
      _horizonTicks =
          openEndedHorizon(clip, current: _horizonTicks, step: _horizonStep);
      clip = clip.copyWith(lengthTicks: _horizonTicks);
    }
    if (from != null) _player.startAt(key, from);
    _player
        .play(key, clip,
            bpm: _bpm,
            voice: _voice,
            takeOver: takeOver,
            loop: openEnded ? false : null)
        .catchError((Object _) {});
    _watchHorizon(openEnded);
  }

  /// How far a drafted clip's playback reaches: past its notes into
  /// silence, pushed further by [_horizonStep] as playback nears it — so a
  /// draft plays on until it's stopped, instead of ending (or cycling) with
  /// its last bar.
  late int _horizonTicks = _horizonStep;
  int get _horizonStep => _timeSignature.barTicks(_ppq) * 8;
  Timer? _horizonTimer;

  void _watchHorizon(bool on) {
    _horizonTimer?.cancel();
    _horizonTimer = on
        ? Timer.periodic(
            const Duration(milliseconds: 500), (_) => _checkHorizon())
        : null;
  }

  void _checkHorizon() {
    final key = _player.playingKey;
    if (!mounted || (!_isOurs && !_preparing)) {
      _watchHorizon(false);
      return;
    }
    if (key == null || _player.paused) return;
    final rendered = durationAtTick(_horizonTicks.toDouble(), _bpm, _ppq);
    if (!needsLongerHorizon(_player.positionOf(key), rendered)) return;
    // Nearly there: render further and swap it in without a gap.
    _horizonTicks += _horizonStep;
    _playHere(takeOver: true);
  }

  void _start() {
    if (_differs || _activeRegion != null || widget.lengthFollowsNotes) {
      _playHere();
    } else {
      _playingRegion = null;
      widget.onPlay(_voice, _bpm);
    }
  }

  /// The ruler was clicked: jump there, or — with this clip not playing —
  /// start playback from there. Cycling a loop region, the spot is found in
  /// it (its start, outside it).
  void _seek(Duration position) {
    final playing = _player.playingKey;
    if (_isOurs && playing != null) {
      _player.seek(playing, _between(position, null, _playingRegion));
    } else if (_differs || _activeRegion != null || widget.lengthFollowsNotes) {
      _playHere(from: _between(position, null, _activeRegion));
    } else {
      _playingRegion = null;
      _player.startAt(widget.playerKey, position);
      widget.onPlay(_voice, _bpm);
    }
  }

  Timer? _regionRestart;

  /// A new loop region. Cycling, playback carries on in it — once it has
  /// settled, not on every step of a drag along the ruler (each would mean
  /// rendering the preview again).
  void _setLoopRegion(MidiTickRange region) {
    setState(() => _loopRegion = region);
    if (!(widget.loop ?? false) || !_isOurs || _player.playingKey == null) {
      return;
    }
    _regionRestart?.cancel();
    _regionRestart = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final from = _playingRegion;
      _restartWith(() {}, at: (p) => _between(p, from, _activeRegion));
    });
  }

  @override
  void didUpdateWidget(MidiPianoRollWindow old) {
    super.didUpdateWidget(old);
    // Looping switched while a loop region is set: playback moves into the
    // region, or back out to the whole clip, from the same spot.
    if ((old.loop ?? false) != (widget.loop ?? false) &&
        (_loopRegion != null || widget.lengthFollowsNotes)) {
      final from = _playingRegion;
      final to = _activeRegion;
      _restartWith(() {}, at: (p) => _between(p, from, to));
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
    final clip = editor.finished.copyWith(name: name);
    final saved = await save(EditedMidiClip(
      clip: clip,
      musicalKey: _scale?.keyText ?? widget.musicalKey,
      voice: _voice,
      bpm: _bpm,
      timeSignature: _timeSignature,
    ));
    if (!saved || !mounted) return;
    editor.markSaved();
    // A drafted clip now has a length: the loop spans it.
    if (widget.lengthFollowsNotes && clip.notes.isNotEmpty) {
      setState(() => _loopRegion = (start: 0, end: clip.lengthTicks));
    }
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
      child: _WindowKeys(
        focusNode: _keys,
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _playPause,
          const SingleActivator(LogicalKeyboardKey.escape): _escape,
          if (widget.onShowShortcuts != null) ...{
            const CharacterActivator('?'): widget.onShowShortcuts!,
            const SingleActivator(LogicalKeyboardKey.f1):
                widget.onShowShortcuts!,
          },
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
            const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                _transpose(editor, 1),
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                _transpose(editor, -1),
            const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
                () => _transpose(editor, 12),
            const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
                () => _transpose(editor, -12),
            // Cubase's tool keys: 1 selects, 8 draws.
            const SingleActivator(LogicalKeyboardKey.digit1): () =>
                _setTool(editor, MidiEditTool.select),
            const SingleActivator(LogicalKeyboardKey.numpad1): () =>
                _setTool(editor, MidiEditTool.select),
            const SingleActivator(LogicalKeyboardKey.digit2): () =>
                _setTool(editor, MidiEditTool.range),
            const SingleActivator(LogicalKeyboardKey.numpad2): () =>
                _setTool(editor, MidiEditTool.range),
            const SingleActivator(LogicalKeyboardKey.digit5): () =>
                _setTool(editor, MidiEditTool.eraser),
            const SingleActivator(LogicalKeyboardKey.numpad5): () =>
                _setTool(editor, MidiEditTool.eraser),
            const SingleActivator(LogicalKeyboardKey.keyQ): () {
              if (editor.editing) editor.quantize();
            },
            // Duplicate: Ctrl+D, or Cmd+D on a Mac.
            const SingleActivator(LogicalKeyboardKey.keyD, control: true):
                editor.duplicate,
            const SingleActivator(LogicalKeyboardKey.keyD, meta: true):
                editor.duplicate,
            const SingleActivator(LogicalKeyboardKey.digit8): () =>
                _setTool(editor, MidiEditTool.pencil),
            const SingleActivator(LogicalKeyboardKey.numpad8): () =>
                _setTool(editor, MidiEditTool.pencil),
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
                  // A press on the notes takes the keyboard back from a
                  // text field (the tempo, say), so the shortcuts work again.
                  child: Listener(
                    onPointerDown: (_) {
                      if (isTypingInTextField() || !_keys.hasFocus) {
                        _keys.requestFocus();
                      }
                    },
                    child: MidiPianoRoll(
                    clip: widget.clip,
                    editor: editor,
                    bpm: _bpm,
                    timeSignature: _timeSignature,
                    labels: labels.roll,
                    positionOf: () {
                      final k = _player.playingKey;
                      if (k == null || !_isOurs) return null;
                      final p = _player.positionOf(k);
                      final region = _playingRegion;
                      if (p == null || region == null) return p;
                      // Cut to the loop region: back to where that is in
                      // the whole clip.
                      return p + durationAtTick(region.start.toDouble(), _bpm, _ppq);
                    },
                    loopRegion: _loopRegion,
                    onLoopRegionChanged: _setLoopRegion,
                    // The loop button and the region's bar are one switch.
                    loopActive: widget.loop ?? false,
                    onLoopToggled: widget.onLoopChanged == null
                        ? null
                        : () => widget.onLoopChanged!(!(widget.loop ?? false)),
                    // A drafted clip opens on room to draw in: four bars.
                    minViewTicks: widget.lengthFollowsNotes
                        ? _timeSignature.barTicks(_ppq) * 4
                        : null,
                    playback: _player,
                    onSeek: _seek,
                    initialScale: scaleFromKey(widget.musicalKey),
                    onScaleChanged: (s) => _scale = s,
                    onAudition: _audition,
                    acousticFeedback: _feedback,
                    onAcousticFeedbackChanged: editor == null
                        ? null
                        : (on) {
                            setState(() => _feedback = on);
                            widget.onAcousticFeedbackChanged?.call(on);
                          },
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
      if (labels.voiceName != null && labels.instrument != null)
        MidiVoicePicker(
          key: const ValueKey('midi-piano-roll-voice'),
          voice: _voice,
          voiceName: labels.voiceName!,
          tooltip: labels.instrument!,
          onChanged: _setVoice,
          showName: true,
        ),
      if (labels.tempo != null)
        MidiTempoControl(
          key: const ValueKey('midi-piano-roll-tempo'),
          bpm: _bpm,
          onChanged: _setBpm,
          labels: labels.tempo!,
        ),
      if (labels.timeSignature.isNotEmpty)
        Tooltip(
          message: labels.timeSignature,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TimeSignature>(
              key: const ValueKey('midi-piano-roll-time-signature'),
              value: _timeSignature,
              isDense: true,
              items: [
                for (final ts in {...kTimeSignatureChoices, _timeSignature})
                  DropdownMenuItem(value: ts, child: Text(ts.text)),
              ],
              onChanged: (ts) {
                if (ts != null) _setTimeSignature(ts);
              },
            ),
          ),
        ),
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
      if (widget.onShowShortcuts != null)
        IconButton(
          key: const ValueKey('midi-piano-roll-shortcuts'),
          tooltip: labels.shortcuts,
          icon: const Icon(Icons.keyboard_outlined),
          onPressed: widget.onShowShortcuts,
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
    final full = widget.fullScreen;
    if (full != null && widget.onFullScreenChanged != null) {
      controls.add(IconButton(
        key: const ValueKey('midi-piano-roll-fullscreen'),
        tooltip: full ? labels.exitFullScreen : labels.fullScreen,
        icon: Icon(full ? Icons.fullscreen_exit : Icons.fullscreen),
        onPressed: () => widget.onFullScreenChanged!(!full),
      ));
    }
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
/// controls: below this width its tools (instrument, tempo, time
/// signature, loop, volume…) and the clip's name don't fit in one row.
bool pianoRollHeaderStacked(double width) => width < 1000;

/// Whether the keyboard is with a text field — the tempo, a name — which
/// the window's shortcuts then stand aside for.
bool isTypingInTextField() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// The window's keys: like [CallbackShortcuts], but they stand aside while
/// a text field has the keyboard — typing "8" into the tempo must not pick
/// the pencil, nor Space start playback. Esc there gives the keys back to
/// the window ([focusNode]).
class _WindowKeys extends StatelessWidget {
  const _WindowKeys({
    required this.bindings,
    required this.focusNode,
    required this.child,
  });

  final Map<ShortcutActivator, VoidCallback> bindings;
  final FocusNode focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (isTypingInTextField()) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            focusNode.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        for (final entry in bindings.entries) {
          if (entry.key.accepts(event, HardwareKeyboard.instance)) {
            entry.value();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// How far open-ended playback of [clip] renders: at least its own length
/// and [step] past its last note, never less than it reached before
/// ([current]).
int openEndedHorizon(MidiClip clip, {required int current, required int step}) {
  var end = 0;
  for (final n in clip.notes) {
    if (n.endTick > end) end = n.endTick;
  }
  return [current, clip.lengthTicks, end + step].reduce((a, b) => a > b ? a : b);
}

/// Whether open-ended playback at [position] has come within [lead] of
/// the end of what was rendered: time to render further.
bool needsLongerHorizon(Duration? position, Duration rendered,
        {Duration lead = const Duration(seconds: 3)}) =>
    position != null && position >= rendered - lead;
