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

/// The kinds of MIDI channel event a clip carries besides its notes, each
/// with the status nibble it is written with.
enum MidiEventKind {
  /// A control change: `number` is the controller (1 mod wheel, 7 volume,
  /// 64 sustain…), `value` 0–127.
  controller(0xB0),

  /// `value` is 0–16383, 8192 being the wheel at rest.
  pitchBend(0xE0),

  /// Aftertouch for the whole channel, `value` 0–127.
  channelPressure(0xD0),

  /// Aftertouch for one key: `number` is the pitch, `value` 0–127.
  polyPressure(0xA0),

  /// `value` is the program (patch) number, 0–127.
  program(0xC0);

  const MidiEventKind(this.status);

  final int status;

  /// The highest `value` this kind holds.
  int get maxValue => this == pitchBend ? 16383 : 127;

  /// The kind written with status byte [status] (any channel), or null for
  /// notes, system messages and anything else.
  static MidiEventKind? ofStatus(int status) {
    final type = status & 0xF0;
    for (final k in values) {
      if (k.status == type) return k;
    }
    return null;
  }
}

/// One non-note event of a [MidiClip] — a controller move, pitch bend,
/// aftertouch or program change — in ticks relative to the clip's start.
class MidiEvent {
  const MidiEvent({
    required this.tick,
    required this.kind,
    required this.value,
    this.number = 0,
    this.channel = 0,
  });

  final int tick;
  final MidiEventKind kind;

  /// The controller number for [MidiEventKind.controller], the pitch for
  /// [MidiEventKind.polyPressure]; 0 for the rest.
  final int number;

  /// 0–127, or 0–16383 for pitch bend (see [MidiEventKind.maxValue]).
  final int value;

  /// 0–15.
  final int channel;

  /// CC 120–127: All Sound Off, Reset All Controllers, All Notes Off and
  /// the rest of MIDI's channel-mode messages. They are housekeeping, not
  /// music — REAPER ends every MIDI source with an All Notes Off — so the
  /// readers leave them out of a clip.
  bool get isChannelMode =>
      kind == MidiEventKind.controller && number >= 120;

  /// The same event moved to [tick].
  MidiEvent at(int tick) => MidiEvent(
        tick: tick,
        kind: kind,
        number: number,
        value: value,
        channel: channel,
      );

  /// Which stream of values this event belongs to: one per kind, controller
  /// number (or key) and channel. A later event on the same lane replaces
  /// this one's value.
  int get laneKey =>
      (kind.index << 12) | ((number & 0x7F) << 4) | (channel & 0x0F);

  @override
  bool operator ==(Object other) =>
      other is MidiEvent &&
      tick == other.tick &&
      kind == other.kind &&
      number == other.number &&
      value == other.value &&
      channel == other.channel;

  @override
  int get hashCode => Object.hash(tick, kind, number, value, channel);

  @override
  String toString() =>
      'MidiEvent($tick ${kind.name} #$number=$value ch$channel)';
}

/// [events] sorted by tick, with what a DAW would not send dropped: of two
/// events on the same lane at the same tick only the later one counts, and
/// an event that sets a lane to the value it already has changes nothing.
///
/// Ableton writes a step as two points at one time, and a clip envelope
/// that holds still as the same value again and again; without this a
/// clip's events would depend on how the DAW happened to store them.
List<MidiEvent> normalizeMidiEvents(Iterable<MidiEvent> events) {
  final indexed = events.toList();
  // Stable: events at one tick keep their order, so "the later one" is the
  // one the DAW wrote later.
  final order = List<int>.generate(indexed.length, (i) => i)
    ..sort((a, b) {
      final c = indexed[a].tick.compareTo(indexed[b].tick);
      return c != 0 ? c : a.compareTo(b);
    });
  final sorted = [for (final i in order) indexed[i]];

  final lastAtTick = <int, int>{}; // laneKey -> index into sorted, this tick
  final keep = List<bool>.filled(sorted.length, true);
  for (var i = 0; i < sorted.length; i++) {
    if (i > 0 && sorted[i].tick != sorted[i - 1].tick) lastAtTick.clear();
    final previous = lastAtTick[sorted[i].laneKey];
    if (previous != null) keep[previous] = false;
    lastAtTick[sorted[i].laneKey] = i;
  }

  final current = <int, int>{}; // laneKey -> value
  final out = <MidiEvent>[];
  for (var i = 0; i < sorted.length; i++) {
    if (!keep[i]) continue;
    final e = sorted[i];
    if (current[e.laneKey] == e.value) continue;
    current[e.laneKey] = e.value;
    out.add(e);
  }
  return out;
}

/// A MIDI clip/part/item read out of a DAW project, normalised to what you'd
/// hear: only the notes inside the clip's visible window, looped content
/// unrolled, positions re-based so the clip starts at tick 0.
///
/// Kept per project in its own box (see `StoredMidiClips` and
/// `MidiClipStore`), never on the project itself: note data can run to
/// megabytes.
class MidiClip {
  const MidiClip({
    required this.name,
    required this.ppq,
    required this.lengthTicks,
    required this.notes,
    this.events = const [],
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

  /// Controller moves, pitch bend, aftertouch and program changes, sorted by
  /// tick and normalised (see [normalizeMidiEvents]). Empty for most clips,
  /// and for every format whose reader doesn't get them yet.
  final List<MidiEvent> events;

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
    String? name,
    int? occurrences,
    int? lengthTicks,
    List<MidiNote>? notes,
    List<MidiEvent>? events,
    List<String>? otherNames,
  }) =>
      MidiClip(
        name: name ?? this.name,
        trackName: trackName,
        ppq: ppq,
        lengthTicks: lengthTicks ?? this.lengthTicks,
        notes: notes ?? this.notes,
        events: events ?? this.events,
        occurrences: occurrences ?? this.occurrences,
        otherNames: otherNames ?? this.otherNames,
      );

  /// What the clip *plays*, independent of what anyone called it: its length,
  /// notes and events, converted to a common 960 PPQ so the same riff at two
  /// resolutions still matches. Name, track and MIDI channel are not part of
  /// it — a renamed copy, or the same line on a second synth, is still the
  /// same clip. A bend or a filter sweep is: it exports as different MIDI.
  ///
  /// A clip with no events has exactly the key it had before clips carried
  /// events, so stored clips and collections keep their identity.
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
    if (events.isNotEmpty) {
      buffer.write('|e');
      for (final e in events) {
        buffer
          ..write(t(e.tick))
          ..write(',')
          ..write(e.kind.status)
          ..write(',')
          ..write(e.number)
          ..write(',')
          ..write(e.value)
          ..write(';');
      }
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
    if (!_sameNotes(tiled, clip.notes)) continue;
    final firstEvents = [for (final e in clip.events) if (e.tick < period) e];
    if (clip.events.isNotEmpty) {
      final tiledEvents = windowMidiEvents(
        firstEvents,
        windowStart: 0,
        windowLength: clip.lengthTicks,
        loop: true,
        loopStart: 0,
        loopEnd: period,
      );
      if (!_sameEvents(tiledEvents, clip.events)) continue;
    }
    return clip.copyWith(
      lengthTicks: period,
      notes: windowMidiNotes(first, windowStart: 0, windowLength: period),
      events:
          windowMidiEvents(firstEvents, windowStart: 0, windowLength: period),
    );
  }
  return clip;
}

/// Event lists compared channel-blind, like notes: the same line on a second
/// channel is the same clip.
bool _sameEvents(List<MidiEvent> a, List<MidiEvent> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final p = a[i], q = b[i];
    if (p.tick != q.tick ||
        p.kind != q.kind ||
        p.number != q.number ||
        p.value != q.value) {
      return false;
    }
  }
  return true;
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

/// [windowMidiNotes] for a clip's events, with the same window and loop.
///
/// A controller keeps its value until it next moves, so what was set before
/// a stretch starts still holds in it: wherever playback enters the source
/// — the window start, and the loop start on every pass — each lane's last
/// earlier value is restated at that point, the way DAWs chase controllers.
/// The result is normalised ([normalizeMidiEvents]).
List<MidiEvent> windowMidiEvents(
  List<MidiEvent> events, {
  required int windowStart,
  required int windowLength,
  bool loop = false,
  int? loopStart,
  int? loopEnd,
}) {
  if (windowLength <= 0 || events.isEmpty) return const [];
  final sorted = normalizeMidiEvents(events);
  final out = <MidiEvent>[];

  void take(int from, int to, int shift) {
    // Chase: each lane's value as playback enters at [from].
    final held = <int, MidiEvent>{};
    for (final e in sorted) {
      if (e.tick >= from) break;
      held[e.laneKey] = e;
    }
    final at = from + shift;
    if (at >= 0 && at < windowLength) {
      for (final e in held.values) {
        out.add(e.at(at));
      }
    }
    for (final e in sorted) {
      if (e.tick < from || e.tick >= to) continue;
      final tick = e.tick + shift;
      if (tick < 0 || tick >= windowLength) continue;
      out.add(e.at(tick));
    }
  }

  final ls = loopStart ?? 0;
  final le = loopEnd ?? 0;
  if (!loop || le <= ls || windowStart >= le) {
    take(windowStart, windowStart + windowLength, -windowStart);
  } else {
    take(windowStart, le, -windowStart);
    var cursor = le - windowStart;
    final cycle = le - ls;
    var guard = 0;
    while (cursor < windowLength && guard++ < 10000) {
      take(ls, le, cursor - ls);
      cursor += cycle;
    }
  }
  return normalizeMidiEvents(out);
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
