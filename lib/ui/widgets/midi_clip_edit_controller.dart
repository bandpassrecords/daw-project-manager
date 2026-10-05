import 'package:flutter/foundation.dart';

import '../../models/midi_clip.dart';

/// The grid edits snap to, as a fraction of a beat; [off] doesn't snap.
enum MidiSnap {
  off(0),
  quarter(1),
  eighth(0.5),
  sixteenth(0.25),
  thirtySecond(0.125);

  const MidiSnap(this.beats);

  /// Grid step in beats; 0 for [off].
  final double beats;

  /// How it is shown: "1/16"; [off] is named by the caller.
  String get fraction => switch (this) {
        off => '',
        quarter => '1/4',
        eighth => '1/8',
        sixteenth => '1/16',
        thirtySecond => '1/32',
      };
}

/// Edits one MIDI clip in the piano roll: notes added, moved, resized and
/// deleted, velocities and controller values drawn, with undo and redo.
///
/// The [original] is never touched — a project's clips are read from the
/// DAW file and replaced on every scan — so edits end up as a new clip,
/// saved by whoever opened the editor.
///
/// A drag edits in two steps: preview calls ([moveNote], [resizeNote],
/// [setVelocity], [drawLane]) change [clip] as the pointer moves, each from
/// the state the gesture started in, and [endGesture] makes the result one
/// undo step (or [cancelGesture] drops it). Taps — [addNoteAt],
/// [deleteSelected] — are a step of their own.
///
/// Notes keep their order while editing, so an index stays the same note;
/// [finished] sorts them for saving.
class MidiClipEditController extends ChangeNotifier {
  MidiClipEditController(this.original)
      : _clip = original,
        _committed = original;

  /// The clip as it was opened, or as last saved ([markSaved]).
  MidiClip original;

  MidiClip _clip;
  MidiClip _committed;
  final List<MidiClip> _undo = [];
  final List<MidiClip> _redo = [];

  /// The clip as shown now, mid-gesture included.
  MidiClip get clip => _clip;

  /// The clip as of the last finished edit — what undo goes back from, and
  /// what a player should play (a drag in progress is not a change yet).
  MidiClip get committed => _committed;

  /// Whether the piano roll is editing (otherwise it only views).
  bool get editing => _editing;
  bool _editing = false;
  set editing(bool value) {
    if (_editing == value) return;
    _editing = value;
    if (!value) _selected = null;
    notifyListeners();
  }

  MidiSnap get snap => _snap;
  MidiSnap _snap = MidiSnap.sixteenth;
  set snap(MidiSnap value) {
    if (_snap == value) return;
    _snap = value;
    notifyListeners();
  }

  /// The selected note's index into [clip]'s notes, if any.
  int? get selected => _selected;
  int? _selected;
  void select(int? index) {
    final valid = index != null && index >= 0 && index < _clip.notes.length;
    final next = valid ? index : null;
    if (next == _selected) return;
    _selected = next;
    notifyListeners();
  }

  /// The velocity a new note gets: the last one set or added.
  int velocity = 100;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Whether the clip differs from [original] — what makes saving worth it.
  bool get edited => !identical(_committed, original);

  /// One grid step in ticks at the clip's PPQ; 1 when not snapping.
  int get stepTicks => _snap == MidiSnap.off
      ? 1
      : (_clip.ppq * _snap.beats).round().clamp(1, 1 << 30);

  /// [tick] on the grid: the step it falls in (floor) — where a click puts
  /// a note.
  int snapDown(double tick) {
    final step = stepTicks;
    final t = tick < 0 ? 0 : tick;
    return (t / step).floor() * step;
  }

  /// [ticks] (a distance) rounded to the nearest whole step — how far a drag
  /// moves a note.
  int snapDelta(double ticks) {
    final step = stepTicks;
    return (ticks / step).round() * step;
  }

  // --- one-step edits --------------------------------------------------------

  /// Adds a note one step long at the grid step [tick] falls in, on
  /// [pitch], and selects it.
  void addNoteAt(double tick, int pitch) {
    final start = snapDown(tick);
    final length = _snap == MidiSnap.off ? _clip.ppq ~/ 4 : stepTicks;
    final note = MidiNote(
      startTick: start,
      lengthTicks: length < 1 ? 1 : length,
      pitch: pitch.clamp(0, 127),
      velocity: velocity.clamp(1, 127),
    );
    _apply(_withNotes(_committed, [..._committed.notes, note]));
    _selected = _clip.notes.length - 1;
    _commit();
  }

  /// Deletes the selected note.
  void deleteSelected() {
    final index = _selected;
    if (index == null || !_editing) return;
    final notes = [..._committed.notes]..removeAt(index);
    _selected = null;
    _apply(_withNotes(_committed, notes));
    _commit();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_committed);
    _committed = _clip = _undo.removeLast();
    _selected = null;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_committed);
    _committed = _clip = _redo.removeLast();
    _selected = null;
    notifyListeners();
  }

  // --- gestures ------------------------------------------------------------

  /// Moves note [index] by [deltaTicks] (snapped) and [deltaPitch] from
  /// where it was when the gesture started.
  void moveNote(int index, double deltaTicks, int deltaPitch) {
    final from = _noteAtStart(index);
    if (from == null) return;
    final start = (from.startTick + snapDelta(deltaTicks)).clamp(0, 1 << 30);
    _replace(
      index,
      MidiNote(
        startTick: start,
        lengthTicks: from.lengthTicks,
        pitch: (from.pitch + deltaPitch).clamp(0, 127),
        velocity: from.velocity,
        channel: from.channel,
      ),
    );
  }

  /// Stretches note [index] so it ends at [endTick] (on the grid), at least
  /// one step long.
  void resizeNote(int index, double endTick) {
    final from = _noteAtStart(index);
    if (from == null) return;
    final step = stepTicks;
    final end = (endTick / step).round() * step;
    final length = end - from.startTick;
    _replace(
      index,
      MidiNote(
        startTick: from.startTick,
        lengthTicks: length < step ? step : length,
        pitch: from.pitch,
        velocity: from.velocity,
        channel: from.channel,
      ),
    );
  }

  /// Sets note [index]'s velocity (1–127).
  void setVelocity(int index, int value) {
    final from = _noteAtStart(index);
    if (from == null) return;
    final v = value.clamp(1, 127);
    velocity = v;
    _replace(
      index,
      MidiNote(
        startTick: from.startTick,
        lengthTicks: from.lengthTicks,
        pitch: from.pitch,
        velocity: v,
        channel: from.channel,
      ),
    );
  }

  /// Sets the controller lane ([kind], [number]) to [value] over the grid
  /// step [tick] falls in — what dragging across a lane draws. Repeated
  /// calls in one gesture build up a curve.
  void drawLane(MidiEventKind kind, int number, double tick, int value) {
    final start = snapDown(tick);
    final end = start + stepTicks;
    final v = value.clamp(0, kind.maxValue);
    bool sameLane(MidiEvent e) =>
        e.kind == kind &&
        (kind != MidiEventKind.controller || e.number == number);
    final events = [
      for (final e in _clip.events)
        if (!(sameLane(e) && e.tick >= start && e.tick < end)) e,
      MidiEvent(
        tick: start,
        kind: kind,
        number: kind == MidiEventKind.controller ? number : 0,
        value: v,
      ),
    ];
    _apply(_clip.copyWith(events: normalizeMidiEvents(events)));
  }

  /// Makes the gesture's changes one undo step.
  void endGesture() {
    if (identical(_clip, _committed)) return;
    _commit();
  }

  /// Drops the gesture's changes — a second finger landing mid-drag, say.
  void cancelGesture() {
    if (identical(_clip, _committed)) return;
    _clip = _committed;
    notifyListeners();
  }

  // --- saving --------------------------------------------------------------

  /// The edited clip ready to keep: notes in order, and the length grown to
  /// the bar the last note ends in if edits ran past it.
  MidiClip get finished {
    final notes = [..._committed.notes]..sort((a, b) {
        final c = a.startTick.compareTo(b.startTick);
        return c != 0 ? c : a.pitch.compareTo(b.pitch);
      });
    var length = _committed.lengthTicks;
    final bar = _committed.ppq * 4;
    for (final n in notes) {
      if (n.endTick > length) length = ((n.endTick + bar - 1) ~/ bar) * bar;
    }
    return _committed.copyWith(notes: notes, lengthTicks: length);
  }

  /// The edits were saved: what is on screen is the new [original].
  void markSaved() {
    original = _committed;
    notifyListeners();
  }

  // --- internals -----------------------------------------------------------

  MidiNote? _noteAtStart(int index) =>
      index >= 0 && index < _committed.notes.length
          ? _committed.notes[index]
          : null;

  void _replace(int index, MidiNote note) {
    final notes = [..._committed.notes];
    notes[index] = note;
    _apply(_withNotes(_committed, notes));
  }

  static MidiClip _withNotes(MidiClip clip, List<MidiNote> notes) =>
      clip.copyWith(notes: notes);

  void _apply(MidiClip next) {
    _clip = next;
    notifyListeners();
  }

  void _commit() {
    _undo.add(_committed);
    _redo.clear();
    _committed = _clip;
    notifyListeners();
  }
}
