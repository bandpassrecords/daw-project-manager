import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';

/// Reads tracks, plug-ins and MIDI clips out of an already-parsed Ableton
/// Live set (`.als` is gzipped XML; `MetadataExtractor` does the unzipping).
///
/// * Tracks are the direct children of `LiveSet/Tracks`: `AudioTrack`,
///   `MidiTrack`, `GroupTrack`, and `ReturnTrack`. Groups and returns count
///   as buses. Live has no separate folder track; a group is both.
/// * Plug-ins are `PluginDevice`/`AuPluginDevice` elements, named by the
///   `Name` (VST3/AU/CLAP) or `PlugName` (VST2) child of their `*PluginInfo`.
///   Live's own devices (`Eq8`, `Compressor2`…) aren't listed: their element
///   names aren't the names Live shows.
/// * A `MidiClip`'s notes sit in `Notes/KeyTracks/KeyTrack`, one key track per
///   pitch (`MidiKey`), each holding `MidiNoteEvent`s timed in beats. What the
///   clip plays starts at `LoopStart + StartRelative` and lasts
///   `CurrentEnd − CurrentStart` beats, wrapping over the loop brace when
///   `LoopOn` is set.
/// * A MIDI clip's controller data is in its clip envelopes
///   (`Envelopes/Envelopes/ClipEnvelope`), each pointing (`PointeeId`) at
///   one of its track's `MidiControllers/ControllerTargets.N`: N = 0 is
///   pitch bend (−8192…8191), 1 channel pressure, and 2–129 CC 0–127 (of
///   which the channel-mode ones, 120 and up, are skipped).
///   Envelopes on device parameters aren't MIDI and are skipped. Points are
///   joined by straight ramps, which are sampled into steps.
class AbletonProjectParser {
  AbletonProjectParser(this.document);

  final XmlDocument document;

  /// Resolution clips are converted to. Live stores beats as decimals, so any
  /// fine PPQ works; 960 keeps triplets and 1/64ths exact.
  static const int ppq = 960;

  XmlElement? get _liveSet =>
      document.rootElement.getElement('LiveSet');

  ProjectStats readStats({bool countMidiClips = true}) {
    final tracks = _liveSet?.getElement('Tracks');
    var audio = 0, midi = 0, bus = 0;
    for (final t in tracks?.childElements ?? const <XmlElement>[]) {
      switch (t.name.local) {
        case 'AudioTrack':
          audio++;
        case 'MidiTrack':
          midi++;
        case 'GroupTrack':
        case 'ReturnTrack':
          bus++;
      }
    }
    return ProjectStats(
      audioTracks: audio,
      midiTracks: midi,
      busTracks: bus,
      plugins: normalizePluginNames(readPluginNames()),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
  }

  List<String> readPluginNames() {
    final names = <String>[];
    for (final desc in document.findAllElements('PluginDesc')) {
      for (final info in desc.childElements) {
        final name = _value(info.getElement('Name')) ??
            _value(info.getElement('PlugName'));
        if (name != null && name.trim().isNotEmpty) {
          names.add(name);
          break;
        }
      }
    }
    return names;
  }

  List<MidiClip> readMidiClips() {
    final clips = <MidiClip>[];
    for (final clip in document.findAllElements('MidiClip')) {
      final parsed = _parseClip(clip);
      if (parsed != null) clips.add(parsed);
    }
    return dedupeMidiClips(clips);
  }

  MidiClip? _parseClip(XmlElement clip) {
    final currentStart = _num(clip.getElement('CurrentStart'));
    final currentEnd = _num(clip.getElement('CurrentEnd'));
    final loop = clip.getElement('Loop');
    if (currentStart == null || currentEnd == null || loop == null) return null;
    final loopStart = _num(loop.getElement('LoopStart')) ?? 0;
    final loopEnd = _num(loop.getElement('LoopEnd')) ?? 0;
    final startRelative = _num(loop.getElement('StartRelative')) ?? 0;
    final loopOn = _value(loop.getElement('LoopOn')) == 'true';

    final source = <MidiNote>[];
    final keyTracks =
        clip.getElement('Notes')?.getElement('KeyTracks')?.childElements ??
            const <XmlElement>[];
    for (final keyTrack in keyTracks) {
      final pitch = _num(keyTrack.getElement('MidiKey'))?.round();
      if (pitch == null || pitch < 0 || pitch > 127) continue;
      final events = keyTrack.getElement('Notes')?.childElements ??
          const <XmlElement>[];
      for (final e in events) {
        if (e.name.local != 'MidiNoteEvent') continue;
        if (e.getAttribute('IsEnabled') == 'false') continue;
        final time = double.tryParse(e.getAttribute('Time') ?? '');
        final duration = double.tryParse(e.getAttribute('Duration') ?? '');
        final velocity = double.tryParse(e.getAttribute('Velocity') ?? '');
        if (time == null || duration == null) continue;
        source.add(MidiNote(
          startTick: _ticks(time),
          lengthTicks: _ticks(duration) < 1 ? 1 : _ticks(duration),
          pitch: pitch,
          velocity: (velocity ?? 100).round().clamp(1, 127),
        ));
      }
    }

    final notes = windowMidiNotes(
      source,
      windowStart: _ticks(loopStart + startRelative),
      windowLength: _ticks(currentEnd - currentStart),
      loop: loopOn,
      loopStart: _ticks(loopStart),
      loopEnd: _ticks(loopEnd),
    );
    final events = windowMidiEvents(
      _envelopeEvents(clip),
      windowStart: _ticks(loopStart + startRelative),
      windowLength: _ticks(currentEnd - currentStart),
      loop: loopOn,
      loopStart: _ticks(loopStart),
      loopEnd: _ticks(loopEnd),
    );
    return MidiClip(
      name: _value(clip.getElement('Name')) ?? '',
      trackName: _trackNameOf(clip),
      ppq: ppq,
      lengthTicks: _ticks(currentEnd - currentStart),
      notes: notes,
      events: events,
    );
  }

  /// A clip's MIDI controller envelopes as events, in the same beat-based
  /// time as its notes (before windowing).
  List<MidiEvent> _envelopeEvents(XmlElement clip) {
    final envelopes = clip
        .getElement('Envelopes')
        ?.getElement('Envelopes')
        ?.findElements('ClipEnvelope');
    if (envelopes == null || envelopes.isEmpty) return const [];
    final targets = _controllerTargetsOf(clip);
    if (targets.isEmpty) return const [];

    final out = <MidiEvent>[];
    for (final envelope in envelopes) {
      final pointee = _value(envelope
          .getElement('EnvelopeTarget')
          ?.getElement('PointeeId'));
      final target = targets[pointee];
      if (target == null) continue;
      final (kind, number) = target;
      final points = <(double, double)>[];
      for (final e in envelope
              .getElement('Automation')
              ?.getElement('Events')
              ?.findElements('FloatEvent') ??
          const <XmlElement>[]) {
        final time = double.tryParse(e.getAttribute('Time') ?? '');
        final value = double.tryParse(e.getAttribute('Value') ?? '');
        if (time != null && value != null) points.add((time, value));
      }
      out.addAll(envelopeToEvents(points, kind: kind, number: number));
    }
    return out;
  }

  final _targetsByTrack = <XmlElement, Map<String, (MidiEventKind, int)>>{};

  /// PointeeId → what it controls, for the MIDI track [clip] sits on.
  Map<String, (MidiEventKind, int)> _controllerTargetsOf(XmlElement clip) {
    XmlElement? track;
    for (final a in clip.ancestorElements) {
      if (a.name.local == 'MidiTrack') {
        track = a;
        break;
      }
    }
    if (track == null) return const {};
    return _targetsByTrack.putIfAbsent(track, () {
      final controllers = track!
          .getElement('DeviceChain')
          ?.getElement('MainSequencer')
          ?.getElement('MidiControllers');
      final map = <String, (MidiEventKind, int)>{};
      for (final t in controllers?.childElements ?? const <XmlElement>[]) {
        final name = t.name.local;
        if (!name.startsWith('ControllerTargets.')) continue;
        final n = int.tryParse(name.substring('ControllerTargets.'.length));
        final id = t.getAttribute('Id');
        if (n == null || id == null) continue;
        final target = switch (n) {
          0 => (MidiEventKind.pitchBend, 0),
          1 => (MidiEventKind.channelPressure, 0),
          >= 2 && <= 121 => (MidiEventKind.controller, n - 2),
          _ => null,
        };
        if (target != null) map[id] = target;
      }
      return map;
    });
  }

  /// Turns an Ableton envelope's points — (beats, value), in the order Live
  /// stores them — into MIDI events.
  ///
  /// Two points at one time are a step. Between two points at different
  /// times Live ramps in a straight line, so the ramp is sampled every 1/32
  /// of a beat (coarser on very long ramps) and each sample becomes an
  /// event; [normalizeMidiEvents] later drops the samples that didn't change
  /// the value. Live's first point sits at a huge negative time to say "the
  /// value before anything else": it is never ramped from.
  ///
  /// Pitch bend arrives as −8192…8191 and is shifted to MIDI's 0…16383.
  static List<MidiEvent> envelopeToEvents(
    List<(double, double)> points, {
    required MidiEventKind kind,
    int number = 0,
  }) {
    int midiValue(double v) => kind == MidiEventKind.pitchBend
        ? (v + 8192).round().clamp(0, 16383)
        : v.round().clamp(0, 127);
    MidiEvent event(double beats, double v) => MidiEvent(
          tick: _ticks(beats),
          kind: kind,
          number: number,
          value: midiValue(v),
        );

    final out = <MidiEvent>[];
    for (var i = 0; i < points.length; i++) {
      final (time, value) = points[i];
      out.add(event(time, value));
      if (i + 1 >= points.length) continue;
      final (nextTime, nextValue) = points[i + 1];
      if (time < 0 || nextTime <= time || midiValue(nextValue) == midiValue(value)) {
        continue;
      }
      final span = nextTime - time;
      final step = math.max(1 / 32, span / 512);
      for (var t = time + step; t < nextTime; t += step) {
        out.add(event(t, value + (nextValue - value) * (t - time) / span));
      }
    }
    return out;
  }

  String? _trackNameOf(XmlElement clip) {
    for (final a in clip.ancestorElements) {
      if (a.name.local == 'MidiTrack' || a.name.local == 'AudioTrack') {
        final name = a.getElement('Name');
        final effective = _value(name?.getElement('EffectiveName'));
        final user = _value(name?.getElement('UserName'));
        if (user != null && user.isNotEmpty) return user;
        return effective;
      }
    }
    return null;
  }

  static int _ticks(double beats) => (beats * ppq).round();

  static String? _value(XmlElement? e) => e?.getAttribute('Value');

  static double? _num(XmlElement? e) => double.tryParse(_value(e) ?? '');
}
