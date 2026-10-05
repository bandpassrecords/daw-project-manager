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

/// Which edge of a note a resize drags.
enum NoteEdge { start, end }

/// Edits one MIDI clip in the piano roll the way Cubase's key editor does:
/// notes added and deleted, a selection of any number of notes moved,
/// transposed, resized from either edge and duplicated, velocities and
/// controller values drawn, with undo and redo.
///
/// The [original] is never touched — a project's clips are read from the
/// DAW file and replaced on every scan — so edits end up as a new clip,
/// saved by whoever opened the editor.
///
/// A drag edits in three steps: [beginGesture] fixes the state it starts
/// from (copying the selection first for an Alt-drag), preview calls
/// ([moveSelection], [resizeSelection], [setVelocity], [drawLane]) change
/// [clip] as the pointer moves — each from that starting state — and
/// [endGesture] makes the result one undo step (or [cancelGesture] drops
/// it). Single actions — [addNoteAt], [deleteNote], [deleteSelected],
/// [transposeSelection] — are a step of their own.
///
/// Notes keep their order while editing, so an index stays the same note;
/// [finished] sorts them for saving.
class MidiClipEditController extends ChangeNotifier {
  MidiClipEditController(this.original)
      : _clip = original,
        _committed = original,
        _base = original;

  /// The clip as it was opened, or as last saved ([markSaved]).
  MidiClip original;

  MidiClip _clip;
  MidiClip _committed;
  final List<MidiClip> _undo = [];
  final List<MidiClip> _redo = [];

  /// What the gesture under way edits from.
  MidiClip _base;

  /// The gesture under way copied the selection (an Alt-drag); a copy that
  /// never moved is dropped rather than left on top of its original.
  bool _duplicating = false;

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
    if (!value) _selection.clear();
    notifyListeners();
  }

  MidiSnap get snap => _snap;
  MidiSnap _snap = MidiSnap.sixteenth;
  set snap(MidiSnap value) {
    if (_snap == value) return;
    _snap = value;
    notifyListeners();
  }

  // --- selection -------------------------------------------------------------

  final Set<int> _selection = {};

  /// The selected notes, as indices into [clip]'s notes.
  Set<int> get selection => Set.unmodifiable(_selection);

  /// The one selected note, when exactly one is.
  int? get selected => _selection.length == 1 ? _selection.first : null;

  bool isSelected(int index) => _selection.contains(index);

  bool _valid(int index) => index >= 0 && index < _clip.notes.length;

  /// Selects [index] alone, or nothing for null.
  void select(int? index) {
    final next = {if (index != null && _valid(index)) index};
    if (setEquals(next, _selection)) return;
    _selection
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// Adds [index] to the selection, or takes it out — Shift-click.
  void toggleSelected(int index) {
    if (!_valid(index)) return;
    if (!_selection.remove(index)) _selection.add(index);
    notifyListeners();
  }

  /// Ctrl/Cmd+A.
  void selectAll() {
    _selection
      ..clear()
      ..addAll([for (var i = 0; i < _clip.notes.length; i++) i]);
    notifyListeners();
  }

  /// Selects the notes a selection box covers: sounding somewhere in
  /// [fromTick]…[toTick] and on a key from [lowPitch] to [highPitch]. With
  /// [keep], they join those already in it (Shift held).
  void selectInBox({
    required double fromTick,
    required double toTick,
    required int lowPitch,
    required int highPitch,
    Set<int> keep = const {},
  }) {
    final next = <int>{...keep.where(_valid)};
    final notes = _clip.notes;
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (n.pitch < lowPitch || n.pitch > highPitch) continue;
      if (n.endTick <= fromTick || n.startTick >= toTick) continue;
      next.add(i);
    }
    if (setEquals(next, _selection)) return;
    _selection
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// The velocity a new note gets: the last one set or added.
  int velocity = 100;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Whether the clip differs from [original] — what makes saving worth it.
  bool get edited => !identical(_committed, original);

  // --- the grid --------------------------------------------------------------

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
  /// moves a note — or, [free] (Ctrl held, as in Cubase), to the nearest
  /// tick.
  int snapDelta(double ticks, {bool free = false}) {
    if (free) return ticks.round();
    final step = stepTicks;
    return (ticks / step).round() * step;
  }

  // --- single actions ----------------------------------------------------------

  /// Adds a note one step long at the grid step [tick] falls in, on
  /// [pitch], and selects it — a double-click on an empty spot.
  void addNoteAt(double tick, int pitch) {
    final start = snapDown(tick);
    final length = _snap == MidiSnap.off ? _clip.ppq ~/ 4 : stepTicks;
    final note = MidiNote(
      startTick: start,
      lengthTicks: length < 1 ? 1 : length,
      pitch: pitch.clamp(0, 127),
      velocity: velocity.clamp(1, 127),
    );
    _apply(_committed.copyWith(notes: [..._committed.notes, note]));
    _selection
      ..clear()
      ..add(_clip.notes.length - 1);
    _commit();
  }

  /// Deletes note [index] — a double-click on it.
  void deleteNote(int index) {
    if (!_editing || index < 0 || index >= _committed.notes.length) return;
    _selection.clear();
    _apply(_committed.copyWith(notes: [..._committed.notes]..removeAt(index)));
    _commit();
  }

  /// Deletes every selected note.
  void deleteSelected() {
    if (_selection.isEmpty || !_editing) return;
    final notes = [
      for (var i = 0; i < _committed.notes.length; i++)
        if (!_selection.contains(i)) _committed.notes[i],
    ];
    _selection.clear();
    _apply(_committed.copyWith(notes: notes));
    _commit();
  }

  /// Moves the selection up or down by [semitones] — ↑/↓, or Shift+↑/↓ for
  /// an octave. Moves as far as the keyboard allows without bending the
  /// chord: if one note would leave it, the whole selection stops short.
  void transposeSelection(int semitones) {
    if (_selection.isEmpty || !_editing || semitones == 0) return;
    final delta = _clampPitchDelta(_committed, semitones);
    if (delta == 0) return;
    final notes = [..._committed.notes];
    for (final i in _selection) {
      final n = notes[i];
      notes[i] = _note(n, pitch: n.pitch + delta);
    }
    _apply(_committed.copyWith(notes: notes));
    _commit();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_committed);
    _committed = _clip = _base = _undo.removeLast();
    _selection.clear();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_committed);
    _committed = _clip = _base = _redo.removeLast();
    _selection.clear();
    notifyListeners();
  }

  // --- gestures ----------------------------------------------------------------

  /// Starts a drag from the committed clip. With [duplicate] (Alt held, as
  /// in Cubase) the selected notes are copied first and the copies become
  /// the selection, so the drag moves the copies and leaves the originals.
  void beginGesture({bool duplicate = false}) {
    _base = _committed;
    _duplicating = false;
    if (duplicate && _selection.isNotEmpty) {
      final copies = [for (final i in _selection.toList()..sort()) _base.notes[i]];
      final first = _base.notes.length;
      _base = _base.copyWith(notes: [..._base.notes, ...copies]);
      _selection
        ..clear()
        ..addAll([for (var i = 0; i < copies.length; i++) first + i]);
      _duplicating = true;
    }
    _apply(_base);
  }

  /// Moves the selection by [deltaTicks] (snapped, or not with [free]) and
  /// [deltaPitch] from where it was when the gesture started — never before
  /// the clip's start or off the keyboard, and keeping its shape.
  void moveSelection(double deltaTicks, int deltaPitch, {bool free = false}) {
    if (_selection.isEmpty) return;
    var dt = snapDelta(deltaTicks, free: free);
    var earliest = 1 << 30;
    for (final i in _selection) {
      final s = _base.notes[i].startTick;
      if (s < earliest) earliest = s;
    }
    if (earliest + dt < 0) dt = -earliest;
    final dp = _clampPitchDelta(_base, deltaPitch);
    final notes = [..._base.notes];
    for (final i in _selection) {
      final n = notes[i];
      notes[i] = _note(n, start: n.startTick + dt, pitch: n.pitch + dp);
    }
    _apply(_base.copyWith(notes: notes));
  }

  /// Drags one [edge] of every selected note by [deltaTicks] (snapped, or
  /// not with [free]): the end makes them longer or shorter, the start
  /// moves where they begin and keeps where they end. Never shorter than a
  /// grid step (a tick when free), never before the clip's start.
  void resizeSelection(NoteEdge edge, double deltaTicks, {bool free = false}) {
    if (_selection.isEmpty) return;
    final dt = snapDelta(deltaTicks, free: free);
    final shortest = free ? 1 : stepTicks;
    final notes = [..._base.notes];
    for (final i in _selection) {
      final n = notes[i];
      if (edge == NoteEdge.end) {
        final length = n.lengthTicks + dt;
        notes[i] = _note(n, length: length < shortest ? shortest : length);
      } else {
        final end = n.endTick;
        var start = n.startTick + dt;
        if (start < 0) start = 0;
        if (end - start < shortest) start = end - shortest;
        notes[i] = _note(n, start: start, length: end - start);
      }
    }
    _apply(_base.copyWith(notes: notes));
  }

  /// Sets note [index]'s velocity (1–127), from where it was when the
  /// gesture started.
  void setVelocity(int index, int value) {
    if (index < 0 || index >= _base.notes.length) return;
    final v = value.clamp(1, 127);
    velocity = v;
    final notes = [..._base.notes];
    notes[index] = _note(notes[index], velocity: v);
    _apply(_base.copyWith(notes: notes));
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

  /// Makes the gesture's changes one undo step. A copy that never moved is
  /// dropped: duplicating onto the originals helps nobody.
  void endGesture() {
    if (_duplicating && _copiesUnmoved()) {
      cancelGesture();
      return;
    }
    _duplicating = false;
    if (identical(_clip, _committed)) return;
    _commit();
  }

  /// Drops the gesture's changes — a second finger landing mid-drag, say.
  void cancelGesture() {
    if (_duplicating) _selection.clear();
    _duplicating = false;
    _base = _committed;
    if (identical(_clip, _committed)) return;
    _clip = _committed;
    notifyListeners();
  }

  /// Whether every copy still sits where it was made — on its original.
  bool _copiesUnmoved() => _selection.every((i) =>
      i < _clip.notes.length &&
      i < _base.notes.length &&
      _clip.notes[i] == _base.notes[i]);

  // --- saving ------------------------------------------------------------------

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

  // --- internals -----------------------------------------------------------------

  /// [wanted] semitones, shortened so no selected note of [clip] leaves the
  /// keyboard.
  int _clampPitchDelta(MidiClip clip, int wanted) {
    var low = 127, high = 0;
    for (final i in _selection) {
      final p = clip.notes[i].pitch;
      if (p < low) low = p;
      if (p > high) high = p;
    }
    if (wanted > 0) return wanted.clamp(0, 127 - high);
    return wanted.clamp(-low, 0);
  }

  static MidiNote _note(
    MidiNote n, {
    int? start,
    int? length,
    int? pitch,
    int? velocity,
  }) =>
      MidiNote(
        startTick: start ?? n.startTick,
        lengthTicks: length ?? n.lengthTicks,
        pitch: (pitch ?? n.pitch).clamp(0, 127),
        velocity: velocity ?? n.velocity,
        channel: n.channel,
      );

  void _apply(MidiClip next) {
    _clip = next;
    notifyListeners();
  }

  void _commit() {
    _undo.add(_committed);
    _redo.clear();
    _committed = _clip;
    _base = _committed;
    notifyListeners();
  }
}
