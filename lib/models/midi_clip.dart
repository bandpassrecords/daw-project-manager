/// One note of a [MidiClip], in ticks relative to the clip's start.
class MidiNote {
  const MidiNote({
    required this.startTick,
    required this.lengthTicks,
    required this.pitch,
    required this.velocity,
    this.channel = 0,
  });

  final int startTick;
  final int lengthTicks;

  /// MIDI note number, 0–127 (60 = C3 in Cubase/Ableton naming, C4 in others).
  final int pitch;

  /// 1–127. Clamped by the parsers, so 0 never reaches here as a note-off.
  final int velocity;

  /// 0–15.
  final int channel;

  int get endTick => startTick + lengthTicks;

  @override
  bool operator ==(Object other) =>
      other is MidiNote &&
      startTick == other.startTick &&
      lengthTicks == other.lengthTicks &&
      pitch == other.pitch &&
      velocity == other.velocity &&
      channel == other.channel;

  @override
  int get hashCode =>
      Object.hash(startTick, lengthTicks, pitch, velocity, channel);

  @override
  String toString() => 'MidiNote($startTick+$lengthTicks p$pitch v$velocity)';
}

/// A MIDI clip/part/item read out of a DAW project, normalised to what you'd
/// hear: only the notes inside the clip's visible window, looped content
/// unrolled, positions re-based so the clip starts at tick 0.
///
/// Never stored — clips are read from the project file on demand (see
/// `MidiClipService`), because note data can run to megabytes and the
/// project file is the source of truth anyway.
class MidiClip {
  const MidiClip({
    required this.name,
    required this.ppq,
    required this.lengthTicks,
    required this.notes,
    this.trackName,
    this.occurrences = 1,
    this.otherNames = const [],
  });

  /// The clip/part/item name as shown in the DAW. May be empty.
  final String name;

  /// The track the clip sits on, when the format tells us.
  final String? trackName;

  /// Ticks per quarter note.
  final int ppq;

  final int lengthTicks;

  /// Sorted by start tick, then pitch.
  final List<MidiNote> notes;

  /// How many clips in the project play exactly these notes — copies,
  /// renamed duplicates, and longer clips that only repeat this one.
  final int occurrences;

  /// Labels ("Track – Clip") of the other clips that turned out to be this
  /// one, so a merged entry can say where else it lives.
  final List<String> otherNames;

  double get lengthBeats => lengthTicks / ppq;

  /// "Track – Clip", or whichever of the two exists.
  String get label {
    final track = trackName?.trim() ?? '';
    final clip = name.trim();
    if (track.isEmpty || track == clip) return clip.isEmpty ? track : clip;
    if (clip.isEmpty) return track;
    return '$track – $clip';
  }

  MidiClip copyWith({
    int? occurrences,
    int? lengthTicks,
    List<MidiNote>? notes,
    List<String>? otherNames,
  }) =>
      MidiClip(
        name: name,
        trackName: trackName,
        ppq: ppq,
        lengthTicks: lengthTicks ?? this.lengthTicks,
        notes: notes ?? this.notes,
        occurrences: occurrences ?? this.occurrences,
        otherNames: otherNames ?? this.otherNames,
      );

  /// What the clip *plays*, independent of what anyone called it: its length
  /// and notes, converted to a common 960 PPQ so the same riff at two
  /// resolutions still matches. Name, track and MIDI channel are not part of
  /// it — a renamed copy, or the same line on a second synth, is still the
  /// same clip.
  String get contentKey {
    int t(int ticks) => (ticks * _canonicalPpq / ppq).round();
    final sorted = [...notes]..sort(_compareNotes);
    final buffer = StringBuffer('${t(lengthTicks)}|');
    for (final n in sorted) {
      buffer
        ..write(t(n.startTick))
        ..write(',')
        ..write(t(n.lengthTicks))
        ..write(',')
        ..write(n.pitch)
        ..write(',')
        ..write(n.velocity)
        ..write(';');
    }
    return buffer.toString();
  }
}

const _canonicalPpq = 960;

int _compareNotes(MidiNote a, MidiNote b) {
  var c = a.startTick.compareTo(b.startTick);
  if (c != 0) return c;
  c = a.pitch.compareTo(b.pitch);
  if (c != 0) return c;
  c = a.lengthTicks.compareTo(b.lengthTicks);
  if (c != 0) return c;
  return a.velocity.compareTo(b.velocity);
}

bool _sameNotes(List<MidiNote> a, List<MidiNote> b) {
  if (a.length != b.length) return false;
  final x = [...a]..sort(_compareNotes);
  final y = [...b]..sort(_compareNotes);
  for (var i = 0; i < x.length; i++) {
    final p = x[i], q = y[i];
    if (p.startTick != q.startTick ||
        p.lengthTicks != q.lengthTicks ||
        p.pitch != q.pitch ||
        p.velocity != q.velocity) {
      return false;
    }
  }
  return true;
}

/// Shrinks a clip that only repeats a shorter pattern down to that pattern:
/// the fewest whole 4/4 bars whose notes, looped, reproduce the clip exactly
/// — a final repeat cut short included. A 32-bar kick clip that is one bar
/// played 32 times becomes that one bar. A clip with no exact repeat comes
/// back unchanged.
MidiClip reduceToRepeatingPattern(MidiClip clip) {
  final bar = clip.ppq * 4;
  if (bar <= 0 || clip.notes.isEmpty) return clip;
  for (var period = bar; period < clip.lengthTicks; period += bar) {
    final first = [for (final n in clip.notes) if (n.startTick < period) n];
    if (first.isEmpty) continue;
    final tiled = windowMidiNotes(
      first,
      windowStart: 0,
      windowLength: clip.lengthTicks,
      loop: true,
      loopStart: 0,
      loopEnd: period,
    );
    if (_sameNotes(tiled, clip.notes)) {
      return clip.copyWith(
        lengthTicks: period,
        notes: windowMidiNotes(first, windowStart: 0, windowLength: period),
      );
    }
  }
  return clip;
}

/// Turns every clip read from a project into the set of *unique* clips.
///
/// Each clip is first reduced to its repeating pattern (see
/// [reduceToRepeatingPattern]), then clips that play the same thing —
/// same [MidiClip.contentKey] — collapse into one entry, whatever they were
/// named and wherever they sat. The first one seen keeps its name and track;
/// the others' labels go into [MidiClip.otherNames], and every one adds to
/// [MidiClip.occurrences]. Clips with no notes are dropped. First-seen order.
List<MidiClip> dedupeMidiClips(Iterable<MidiClip> clips) {
  final byKey = <String, MidiClip>{};
  for (final raw in clips) {
    if (raw.notes.isEmpty) continue;
    final clip = reduceToRepeatingPattern(raw);
    final key = clip.contentKey;
    final existing = byKey[key];
    if (existing == null) {
      byKey[key] = clip;
      continue;
    }
    final names = [...existing.otherNames];
    for (final label in [clip.label, ...clip.otherNames]) {
      if (label.isNotEmpty && label != existing.label && !names.contains(label)) {
        names.add(label);
      }
    }
    byKey[key] = existing.copyWith(
      occurrences: existing.occurrences + clip.occurrences,
      otherNames: names,
    );
  }
  return byKey.values.toList();
}

/// Cuts the notes a clip actually plays out of its source content.
///
/// [notes] are positioned relative to the source content's origin. The clip
/// plays [windowLength] ticks starting at [windowStart]. When [loop] is set
/// the source repeats over `[loopStart, loopEnd)` once playback passes
/// `loopEnd` — the way Ableton clips and REAPER items with "loop source" on
/// behave. Notes that start outside the window are dropped (they're the
/// hidden material DAWs keep when a clip is trimmed); notes running past the
/// window's end are shortened to fit.
List<MidiNote> windowMidiNotes(
  List<MidiNote> notes, {
  required int windowStart,
  required int windowLength,
  bool loop = false,
  int? loopStart,
  int? loopEnd,
}) {
  if (windowLength <= 0) return const [];
  final out = <MidiNote>[];

  void take(int from, int to, int shift) {
    for (final n in notes) {
      if (n.startTick < from || n.startTick >= to) continue;
      final start = n.startTick + shift;
      if (start < 0 || start >= windowLength) continue;
      var length = n.lengthTicks;
      if (start + length > windowLength) length = windowLength - start;
      if (length <= 0) continue;
      out.add(MidiNote(
        startTick: start,
        lengthTicks: length,
        pitch: n.pitch,
        velocity: n.velocity,
        channel: n.channel,
      ));
    }
  }

  final ls = loopStart ?? 0;
  final le = loopEnd ?? 0;
  if (!loop || le <= ls || windowStart >= le) {
    take(windowStart, windowStart + windowLength, -windowStart);
  } else {
    // First pass: from the window start to the loop end; then whole loop
    // cycles until the window is full.
    take(windowStart, le, -windowStart);
    var cursor = le - windowStart;
    final cycle = le - ls;
    // Hard cap so a pathological (tiny loop, huge window) can't spin forever.
    var guard = 0;
    while (cursor < windowLength && guard++ < 10000) {
      take(ls, le, cursor - ls);
      cursor += cycle;
    }
  }

  out.sort((a, b) {
    final c = a.startTick.compareTo(b.startTick);
    return c != 0 ? c : a.pitch.compareTo(b.pitch);
  });
  return out;
}

/// One group of clips in a list — a track's clips on a project page, a
/// project's clips in the MIDI library.
class MidiClipGroup {
  const MidiClipGroup(this.label, this.clipIndices);

  /// The heading, or null for the clips nothing could be said about (no
  /// track known, say).
  final String? label;

  /// Indices into the list that was grouped, in their original order.
  final List<int> clipIndices;
}

/// Groups `count` list items by the label [labelOf] gives each, groups in
/// first-seen order and unlabelled items last. Labels are compared trimmed.
List<MidiClipGroup> groupMidiClips(int count, String? Function(int) labelOf) {
  final byLabel = <String, List<int>>{};
  final unlabelled = <int>[];
  for (var i = 0; i < count; i++) {
    final label = labelOf(i)?.trim();
    if (label == null || label.isEmpty) {
      unlabelled.add(i);
    } else {
      (byLabel[label] ??= []).add(i);
    }
  }
  return [
    for (final e in byLabel.entries) MidiClipGroup(e.key, e.value),
    if (unlabelled.isNotEmpty) MidiClipGroup(null, unlabelled),
  ];
}

/// Groups [clips] by [MidiClip.trackName] — a clip's own name is often a DAW
/// default ("MIDI 01", "Diva 01") and the track name is what says what it is
/// for. A merged clip is listed once, under the track it was first found on.
List<MidiClipGroup> groupMidiClipsByTrack(List<MidiClip> clips) =>
    groupMidiClips(clips.length, (i) => clips[i].trackName);
