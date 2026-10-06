import 'dart:math' as math;

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

/// What a click on the notes does, as with Cubase's toolbox (its keys in
/// brackets): [select] (1) selects, moves and resizes — a double-click adds
/// or deletes; [range] (2) selects a stretch of time and every note in it,
/// for [MidiClipEditController.duplicate]; [eraser] (5) deletes whatever it
/// clicks or is dragged over; [pencil] (8) adds a note with a single click
/// (a drag makes it longer) and erases one clicked on.
enum MidiEditTool { select, range, eraser, pencil }

/// A stretch of the clip, in ticks: [start] inclusive, [end] exclusive.
typedef MidiTickRange = ({int start, int end});

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
/// ([moveSelection], [resizeSelection], [drawVelocities], [drawLane]) change
/// [clip] as the pointer moves — each from that starting state — and
/// [endGesture] makes the result one undo step (or [cancelGesture] drops
/// it). The pencil's [beginNote] starts a gesture of its own, so a note
/// drawn and stretched is one step too. Single actions — [addNoteAt], [deleteNote], [deleteSelected],
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

  /// The gesture under way is the pencil drawing a note ([beginNote]); the
  /// note goes if the gesture is cancelled.
  bool _adding = false;

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
    if (!value) {
      _selection.clear();
      _range = null;
    }
    notifyListeners();
  }

  MidiEditTool get tool => _tool;
  MidiEditTool _tool = MidiEditTool.select;
  set tool(MidiEditTool value) {
    if (_tool == value) return;
    _tool = value;
    _range = null;
    notifyListeners();
  }

  /// The stretch of time the range tool selected, if any; its notes are
  /// the selection. Anything else that changes the selection drops it.
  MidiTickRange? get range => _range;
  MidiTickRange? _range;

  /// Selects the stretch between [fromTick] and [toTick] (either way
  /// round), widened to whole grid steps, and every note starting in it.
  void selectRange(double fromTick, double toTick) {
    final step = stepTicks;
    final lo = fromTick < toTick ? fromTick : toTick;
    final hi = fromTick < toTick ? toTick : fromTick;
    final start = snapDown(lo);
    var end = ((hi < 0 ? 0 : hi) / step).ceil() * step;
    if (end <= start) end = start + step;
    final next = (start: start, end: end);
    if (next == _range) return;
    _range = next;
    _selection
      ..clear()
      ..addAll(_notesStartingIn(_clip, next));
    notifyListeners();
  }

  static Iterable<int> _notesStartingIn(MidiClip clip, MidiTickRange r) sync* {
    for (var i = 0; i < clip.notes.length; i++) {
      final t = clip.notes[i].startTick;
      if (t >= r.start && t < r.end) yield i;
    }
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
    final hadRange = _range != null;
    _range = null;
    if (setEquals(next, _selection) && !hadRange) return;
    _selection
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// Adds [index] to the selection, or takes it out — Shift-click.
  void toggleSelected(int index) {
    if (!_valid(index)) return;
    _range = null;
    if (!_selection.remove(index)) _selection.add(index);
    notifyListeners();
  }

  /// Ctrl/Cmd+A.
  void selectAll() {
    _range = null;
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
    _range = null;
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

  /// How finely a drag draws a controller, pitch bend or pressure lane: a
  /// 128th note, whatever the note grid — drawn on the 1/16 grid, a bend
  /// came out as a staircase.
  int get laneStepTicks {
    final step = _clip.ppq ~/ 32;
    return step < 1 ? 1 : step;
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
    _apply(_committed.copyWith(notes: [..._committed.notes, _newNote(tick, pitch)]));
    _range = null;
    _selection
      ..clear()
      ..add(_clip.notes.length - 1);
    _commit();
  }

  /// The pencil: starts a gesture with a new note at the grid step [tick]
  /// falls in, one step long and selected, for [resizeSelection] to
  /// stretch as the pointer drags; [endGesture] keeps it as one undo step.
  void beginNote(double tick, int pitch) {
    _base = _committed.copyWith(
        notes: [..._committed.notes, _newNote(tick, pitch)]);
    _duplicating = false;
    _adding = true;
    _range = null;
    _selection
      ..clear()
      ..add(_base.notes.length - 1);
    _apply(_base);
  }

  /// A note one step long (a 16th with snapping off) at the grid step
  /// [tick] falls in, at the velocity last used.
  MidiNote _newNote(double tick, int pitch) {
    final length = _snap == MidiSnap.off ? _clip.ppq ~/ 4 : stepTicks;
    return MidiNote(
      startTick: snapDown(tick),
      lengthTicks: length < 1 ? 1 : length,
      pitch: pitch.clamp(0, 127),
      velocity: velocity.clamp(1, 127),
    );
  }

  /// Deletes note [index] — a double-click on it.
  void deleteNote(int index) {
    if (!_editing || index < 0 || index >= _committed.notes.length) return;
    _selection.clear();
    _range = null;
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
    _range = null;
    _apply(_committed.copyWith(notes: notes));
    _commit();
  }

  /// Ctrl/Cmd+D, as in Cubase. With a [range]: its notes (cut off at its
  /// end) and controller events are copied straight after it, and the
  /// range moves onto the copy — so pressing it again carries on the
  /// pattern. Otherwise the selected notes are copied to start where the
  /// last of them ends (on the grid, when snapping), and the copies become
  /// the selection. One undo step either way.
  void duplicate() {
    if (!_editing) return;
    final r = _range;
    if (r != null) {
      _duplicateRange(r);
    } else if (_selection.isNotEmpty) {
      _duplicateSelection();
    }
  }

  void _duplicateRange(MidiTickRange r) {
    final length = r.end - r.start;
    final source = _committed;
    final copies = [
      for (final i in _notesStartingIn(source, r))
        _note(
          source.notes[i],
          start: source.notes[i].startTick + length,
          length: math.min(
              source.notes[i].lengthTicks, r.end - source.notes[i].startTick),
        ),
    ];
    final events = [
      for (final e in source.events)
        if (e.tick >= r.start && e.tick < r.end)
          MidiEvent(
              tick: e.tick + length, kind: e.kind, number: e.number, value: e.value),
    ];
    if (copies.isEmpty && events.isEmpty) {
      // Nothing in it: the range still moves on, as an empty bar would.
      _range = (start: r.end, end: r.end + length);
      notifyListeners();
      return;
    }
    final first = source.notes.length;
    _apply(source.copyWith(
      notes: [...source.notes, ...copies],
      events: normalizeMidiEvents([...source.events, ...events]),
    ));
    _commit();
    _range = (start: r.end, end: r.end + length);
    _selection
      ..clear()
      ..addAll([for (var i = 0; i < copies.length; i++) first + i]);
    notifyListeners();
  }

  void _duplicateSelection() {
    final source = _committed;
    final picked = _selection.toList()..sort();
    var start = 1 << 30, end = 0;
    for (final i in picked) {
      final n = source.notes[i];
      if (n.startTick < start) start = n.startTick;
      if (n.endTick > end) end = n.endTick;
    }
    var offset = end - start;
    if (_snap != MidiSnap.off) {
      final step = stepTicks;
      offset = (offset / step).ceil() * step;
    }
    if (offset < 1) offset = 1;
    final first = source.notes.length;
    _apply(source.copyWith(notes: [
      ...source.notes,
      for (final i in picked)
        _note(source.notes[i], start: source.notes[i].startTick + offset),
    ]));
    _selection
      ..clear()
      ..addAll([for (var i = 0; i < picked.length; i++) first + i]);
    _commit();
  }

  /// Q, as in Cubase: moves the start of every selected note — or of every
  /// note, with none selected — to the nearest grid step, keeping lengths.
  /// With snapping off, to the 1/16 grid. One undo step.
  void quantize() {
    if (!_editing) return;
    final step = _snap == MidiSnap.off
        ? (_clip.ppq * MidiSnap.sixteenth.beats).round().clamp(1, 1 << 30)
        : stepTicks;
    final source = _committed;
    final targets = _selection.isEmpty
        ? [for (var i = 0; i < source.notes.length; i++) i]
        : _selection.toList();
    final notes = [...source.notes];
    var changed = false;
    for (final i in targets) {
      final n = notes[i];
      final start = (n.startTick / step).round() * step;
      if (start == n.startTick) continue;
      notes[i] = _note(n, start: start);
      changed = true;
    }
    if (!changed) return;
    _apply(source.copyWith(notes: notes));
    _commit();
  }

  /// The eraser, mid-gesture: removes note [index] of [clip]. A drag erases
  /// note after note; [endGesture] makes it all one undo step.
  void eraseNote(int index) {
    if (index < 0 || index >= _clip.notes.length) return;
    _selection.clear();
    _range = null;
    _apply(_clip.copyWith(notes: [..._clip.notes]..removeAt(index)));
  }

  /// The eraser over a controller lane: removes the lane's events between
  /// [fromTick] and [toTick], the stretch the drag just crossed.
  void eraseLane(MidiEventKind kind, int number, double fromTick, double toTick) {
    final lo = fromTick < toTick ? fromTick : toTick;
    final hi = fromTick < toTick ? toTick : fromTick;
    final step = laneStepTicks;
    final first = (((lo < 0 ? 0 : lo)) / step).floor() * step;
    final last = (((hi < 0 ? 0 : hi)) / step).floor() * step + step;
    bool doomed(MidiEvent e) =>
        e.kind == kind &&
        (kind != MidiEventKind.controller || e.number == number) &&
        e.tick >= first &&
        e.tick < last;
    if (!_clip.events.any(doomed)) return;
    _apply(_clip.copyWith(events: [
      for (final e in _clip.events)
        if (!doomed(e)) e,
    ]));
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
    _range = null;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_committed);
    _committed = _clip = _base = _redo.removeLast();
    _selection.clear();
    _range = null;
    notifyListeners();
  }

  // --- gestures ----------------------------------------------------------------

  /// Starts a drag from the committed clip. With [duplicate] (Alt held, as
  /// in Cubase) the selected notes are copied first and the copies become
  /// the selection, so the drag moves the copies and leaves the originals.
  void beginGesture({bool duplicate = false}) {
    _base = _committed;
    _duplicating = false;
    _adding = false;
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

  /// Sets the velocity of every note starting between [fromTick] and
  /// [toTick] — the stretch of the velocity lane a drag just crossed — on
  /// the line from [fromValue] to [toValue], like a pencil across the
  /// stems. Notes starting together (a chord) all get the value there.
  /// Repeated calls in one gesture shape a whole run of notes.
  void drawVelocities(
      double fromTick, int fromValue, double toTick, int toValue) {
    final (t0, v0, t1, v1) = fromTick <= toTick
        ? (fromTick, fromValue, toTick, toValue)
        : (toTick, toValue, fromTick, fromValue);
    final notes = [..._clip.notes];
    var changed = false;
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (n.startTick < t0 || n.startTick > t1) continue;
      final f = t1 == t0 ? 1.0 : (n.startTick - t0) / (t1 - t0);
      final v = (v0 + (v1 - v0) * f).round().clamp(1, 127);
      velocity = v;
      if (n.velocity == v) continue;
      notes[i] = _note(n, velocity: v);
      changed = true;
    }
    if (changed) _apply(_clip.copyWith(notes: notes));
  }

  /// Draws the lane ([kind], [number]) at [value] where [tick] falls — or,
  /// given [fromTick] and [fromValue] (where the pointer last was), along
  /// the line from there, so a fast drag leaves no gaps. Written every
  /// [laneStepTicks], replacing what the lane held there; repeated calls in
  /// one gesture build up a curve.
  void drawLane(
    MidiEventKind kind,
    int number,
    double tick,
    int value, {
    double? fromTick,
    int? fromValue,
  }) {
    final (t0, v0, t1, v1) = fromTick == null || fromValue == null
        ? (tick, value, tick, value)
        : fromTick <= tick
            ? (fromTick, fromValue, tick, value)
            : (tick, value, fromTick, fromValue);
    final step = laneStepTicks;
    int stepOf(double t) => ((t < 0 ? 0 : t) / step).floor() * step;
    final first = stepOf(t0), last = stepOf(t1);
    // The steps the line starts and ends in hold exactly the values drawn
    // there — so a bend snapped back to the middle ends on it — and the
    // steps between follow the line.
    int valueAt(int t) {
      if (t == last) return v1.clamp(0, kind.maxValue);
      if (t == first) return v0.clamp(0, kind.maxValue);
      final f = ((t - t0) / (t1 - t0)).clamp(0.0, 1.0);
      return (v0 + (v1 - v0) * f).round().clamp(0, kind.maxValue);
    }

    bool sameLane(MidiEvent e) =>
        e.kind == kind &&
        (kind != MidiEventKind.controller || e.number == number);
    final events = [
      for (final e in _clip.events)
        if (!(sameLane(e) && e.tick >= first && e.tick < last + step)) e,
      for (var t = first; t <= last; t += step)
        MidiEvent(
          tick: t,
          kind: kind,
          number: kind == MidiEventKind.controller ? number : 0,
          value: valueAt(t),
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
    _adding = false;
    if (identical(_clip, _committed)) return;
    _commit();
  }

  /// Drops the gesture's changes — a second finger landing mid-drag, say.
  void cancelGesture() {
    if (_duplicating || _adding) _selection.clear();
    _duplicating = false;
    _adding = false;
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
    _committed = _clip = grownToNotes(_clip);
    _base = _committed;
    notifyListeners();
  }
}

/// [clip], grown to the end of the bar its last note ends in when a note
/// runs past its end — so a clip being drawn keeps growing as notes go past
/// it, bar by bar, and its end line, playback and saving follow. [clip]
/// itself when nothing runs past.
MidiClip grownToNotes(MidiClip clip) {
  var end = clip.lengthTicks;
  for (final n in clip.notes) {
    if (n.endTick > end) end = n.endTick;
  }
  if (end <= clip.lengthTicks) return clip;
  final bar = clip.ppq * 4;
  return clip.copyWith(lengthTicks: ((end + bar - 1) ~/ bar) * bar);
}
