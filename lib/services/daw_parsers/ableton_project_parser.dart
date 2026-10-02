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
    return MidiClip(
      name: _value(clip.getElement('Name')) ?? '',
      trackName: _trackNameOf(clip),
      ppq: ppq,
      lengthTicks: _ticks(currentEnd - currentStart),
      notes: notes,
    );
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
