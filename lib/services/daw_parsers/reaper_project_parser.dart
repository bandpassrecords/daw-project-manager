import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';

/// Reads tracks, plug-ins and MIDI items out of a REAPER `.rpp`.
///
/// RPP is a nested text format: a line starting with `<NAME …` opens a chunk,
/// a line holding just `>` closes it, and everything else is a `KEY values…`
/// line belonging to the innermost open chunk. See
/// github.com/ReaTeam/Doc "State Chunk Definitions".
///
/// * Every `<TRACK` is a track. `ISBUS 1 …` makes it a folder parent. A track
///   with an instrument (`VSTi`, `VST3i`, `AUi`, `CLAPi`, `LV2i`) counts as
///   an instrument track; one with MIDI items but no instrument as MIDI; one
///   without items that receives from other tracks (`AUXRECV`) as a bus;
///   everything else as audio — REAPER tracks are all the same kind, so this
///   is a reading of what each one is used for.
/// * Plug-ins are the `<VST`, `<AU`, `<CLAP`, `<LV2`, `<JS` and `<DX` chunks
///   in a track's or the master's FX chain, named by their first quoted
///   argument (`"VST3: Pro-Q 3 (FabFilter)"` → `Pro-Q 3`). Take FX count too.
/// * A MIDI item's events are the `E`/`e` lines of its `<SOURCE MIDI`, each a
///   tick delta (at the `HASDATA 1 <ppq>` resolution) and three hex bytes.
///   Controller, pitch-bend, aftertouch and program-change lines become the
///   clip's events; `Em`/`em` lines are muted and skipped, and so is the
///   All Notes Off (CC 123) REAPER closes every source with.
///   The item plays `LENGTH` seconds from `SOFFS` into the source, looping
///   the source when `LOOP 1` is set. Seconds are converted with the
///   project's `TEMPO`, so items in projects with tempo changes are
///   approximate.
class ReaperProjectParser {
  ReaperProjectParser(this.content);

  final String content;

  late final _RppChunk _root = _RppChunk.parse(content);

  double get _bpm {
    for (final line in _root.lines) {
      if (line.key == 'TEMPO') {
        final v = double.tryParse(line.arg(0) ?? '');
        if (v != null && v > 0 && v < 1000) return v;
      }
    }
    return 120;
  }

  ProjectStats readStats({bool countMidiClips = true}) {
    var audio = 0, midi = 0, instrument = 0, bus = 0, folder = 0;
    final plugins = <String>[];

    for (final fx in _root.descendants(_isPluginChunk)) {
      final name = _pluginDisplayName(fx);
      if (name != null) plugins.add(name);
    }

    for (final track in _root.children.where((c) => c.name == 'TRACK')) {
      final isFolder = track.lines
          .any((l) => l.key == 'ISBUS' && l.arg(0) == '1');
      final items = track.children.where((c) => c.name == 'ITEM').toList();
      final hasMidi = items.any((i) => i
          .descendants((c) => c.name == 'SOURCE' && c.header.arg(0) == 'MIDI')
          .isNotEmpty);
      final hasInstrument = track
          .descendants(_isPluginChunk)
          .any((fx) => _isInstrument(fx.header.arg(0) ?? ''));
      final receives = track.lines.any((l) => l.key == 'AUXRECV');

      if (isFolder && items.isEmpty) {
        folder++;
      } else if (hasInstrument) {
        instrument++;
      } else if (hasMidi) {
        midi++;
      } else if (items.isEmpty && receives) {
        bus++;
      } else {
        audio++;
      }
    }

    return ProjectStats(
      audioTracks: audio,
      midiTracks: midi,
      instrumentTracks: instrument,
      busTracks: bus,
      folderTracks: folder,
      plugins: normalizePluginNames(plugins),
      midiClipCount: countMidiClips ? readMidiClips().length : null,
    );
  }

  List<MidiClip> readMidiClips() {
    final bpm = _bpm;
    final clips = <MidiClip>[];
    for (final track in _root.children.where((c) => c.name == 'TRACK')) {
      final trackName = track.value('NAME');
      for (final item in track.children.where((c) => c.name == 'ITEM')) {
        final source = item.children.firstWhere(
          (c) => c.name == 'SOURCE' && c.header.arg(0) == 'MIDI',
          orElse: () => _RppChunk.empty,
        );
        if (identical(source, _RppChunk.empty)) continue;
        final clip = _parseItem(item, source, bpm, trackName);
        if (clip != null) clips.add(clip);
      }
    }
    return dedupeMidiClips(clips);
  }

  MidiClip? _parseItem(
      _RppChunk item, _RppChunk source, double bpm, String? trackName) {
    final hasData = source.lines.firstWhere((l) => l.key == 'HASDATA',
        orElse: () => const _RppLine('', []));
    final ppq = int.tryParse(hasData.arg(1) ?? '') ?? 960;
    if (ppq <= 0) return null;

    final notes = <MidiNote>[];
    final events = <MidiEvent>[];
    final open = <int, (int, int)>{}; // channel<<8|pitch -> (start, velocity)
    var tick = 0;
    for (final line in source.lines) {
      final k = line.key;
      if (k != 'E' && k != 'e' && k != 'Em' && k != 'em') {
        continue;
      }
      final delta = int.tryParse(line.arg(0) ?? '');
      final status = int.tryParse(line.arg(1) ?? '', radix: 16);
      final d1 = int.tryParse(line.arg(2) ?? '', radix: 16);
      final d2 = int.tryParse(line.arg(3) ?? '', radix: 16);
      if (delta == null || status == null || d1 == null || d2 == null) {
        continue;
      }
      tick += delta;
      if (k.endsWith('m')) continue; // muted event
      final type = status & 0xF0;
      final channel = status & 0x0F;
      final key = (channel << 8) | (d1 & 0x7F);
      if (type == 0x90 && d2 > 0) {
        open[key] = (tick, d2);
      } else if (type == 0x80 || (type == 0x90 && d2 == 0)) {
        final on = open.remove(key);
        if (on != null) {
          notes.add(MidiNote(
            startTick: on.$1,
            lengthTicks: tick - on.$1 < 1 ? 1 : tick - on.$1,
            pitch: d1 & 0x7F,
            velocity: on.$2.clamp(1, 127),
            channel: channel,
          ));
        }
      } else if (MidiEventKind.ofStatus(status) case final kind?) {
        final event = MidiEvent(
          tick: tick,
          kind: kind,
          // Pitch bend is LSB then MSB; program and channel pressure carry
          // their value in the first data byte.
          number: kind == MidiEventKind.controller ||
                  kind == MidiEventKind.polyPressure
              ? d1 & 0x7F
              : 0,
          value: switch (kind) {
            MidiEventKind.pitchBend => ((d2 & 0x7F) << 7) | (d1 & 0x7F),
            MidiEventKind.program || MidiEventKind.channelPressure => d1 & 0x7F,
            _ => d2 & 0x7F,
          },
          channel: channel,
        );
        if (!event.isChannelMode) events.add(event);
      }
    }
    final sourceLength = tick;

    final ticksPerSecond = bpm / 60 * ppq;
    final itemLength = double.tryParse(item.value('LENGTH') ?? '');
    final offset = double.tryParse(item.value('SOFFS') ?? '') ?? 0;
    final loop = item.value('LOOP') == '1';
    final windowLength = itemLength == null
        ? sourceLength
        : (itemLength * ticksPerSecond).round();
    final windowStart = (offset * ticksPerSecond).round();

    final windowed = windowMidiNotes(
      notes,
      windowStart: windowStart,
      windowLength: windowLength,
      loop: loop && sourceLength > 0,
      loopStart: 0,
      loopEnd: sourceLength,
    );
    final windowedEvents = windowMidiEvents(
      events,
      windowStart: windowStart,
      windowLength: windowLength,
      loop: loop && sourceLength > 0,
      loopStart: 0,
      loopEnd: sourceLength,
    );
    // An item's NAME is its first take's name; the item chunk itself may also
    // carry one in older files.
    final name = item.value('NAME') ?? '';
    return MidiClip(
      name: name,
      trackName: trackName,
      ppq: ppq,
      lengthTicks: windowLength,
      notes: windowed,
      events: windowedEvents,
    );
  }

  static const _pluginChunks = {'VST', 'AU', 'CLAP', 'LV2', 'JS', 'DX'};

  static bool _isPluginChunk(_RppChunk c) => _pluginChunks.contains(c.name);

  static final _typePrefix = RegExp(r'^(VST3?i?|AUi?|CLAPi?|LV2i?|DXi?|JS):\s*');

  static bool _isInstrument(String descriptor) =>
      RegExp(r'^(VST3?i|AUi|CLAPi|LV2i|DXi):').hasMatch(descriptor);

  /// `"VST3: Pro-Q 3 (FabFilter)"` → `Pro-Q 3`; `"AU: Apple: AUDelay"` →
  /// `AUDelay`; a JS effect is named by its script path's last segment.
  static String? _pluginDisplayName(_RppChunk fx) {
    final raw = fx.header.arg(0);
    if (raw == null || raw.isEmpty) return null;
    if (fx.name == 'JS') {
      final parts = raw.split('/');
      return parts.last.trim();
    }
    var name = raw.replaceFirst(_typePrefix, '');
    // Trailing "(Vendor)", but only one — "Kick (2) (Sonic Academy)".
    name = name.replaceFirst(RegExp(r'\s*\([^()]*\)\s*$'), '');
    // AU descriptors put the vendor first: "Apple: AUDelay".
    if (fx.name == 'AU' && name.contains(': ')) {
      name = name.substring(name.indexOf(': ') + 2);
    }
    return name.trim().isEmpty ? null : name.trim();
  }
}

class _RppLine {
  const _RppLine(this.key, this.args);
  final String key;
  final List<String> args;
  String? arg(int i) => i < args.length ? args[i] : null;
}

class _RppChunk {
  _RppChunk(this.name, this.header);

  final String name;

  /// The opening line's arguments, e.g. `MIDI` for `<SOURCE MIDI`.
  final _RppLine header;
  final List<_RppLine> lines = [];
  final List<_RppChunk> children = [];

  static final empty = _RppChunk('', const _RppLine('', []));

  String? value(String key) {
    for (final l in lines) {
      if (l.key == key) return l.args.isEmpty ? '' : l.args.first;
    }
    return null;
  }

  Iterable<_RppChunk> descendants(bool Function(_RppChunk) test) sync* {
    for (final c in children) {
      if (test(c)) yield c;
      yield* c.descendants(test);
    }
  }

  static _RppChunk parse(String content) {
    final root = _RppChunk('ROOT', const _RppLine('', []));
    final stack = <_RppChunk>[root];
    var first = true;
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line == '>') {
        if (stack.length > 1) stack.removeLast();
        continue;
      }
      if (line.startsWith('<')) {
        final tokens = _tokenize(line.substring(1));
        if (tokens.isEmpty) continue;
        final chunk = _RppChunk(tokens.first, _RppLine(tokens.first, tokens.sublist(1)));
        // The file's own outer <REAPER_PROJECT …> chunk becomes the root, so
        // top-level TRACKs are the root's direct children.
        if (first && tokens.first == 'REAPER_PROJECT') {
          first = false;
          continue;
        }
        first = false;
        stack.last.children.add(chunk);
        stack.add(chunk);
        continue;
      }
      first = false;
      // MIDI event lines are hot and never quoted — skip the tokenizer.
      final c = line.codeUnitAt(0);
      final tokens = (c == 0x45 || c == 0x65) // 'E' / 'e'
          ? line.split(RegExp(r'\s+'))
          : _tokenize(line);
      if (tokens.isEmpty) continue;
      stack.last.lines.add(_RppLine(tokens.first, tokens.sublist(1)));
    }
    return root;
  }

  /// Splits on whitespace, honouring "double", 'single' and `backtick`
  /// quoted arguments (REAPER picks whichever quote the value doesn't
  /// contain).
  static List<String> _tokenize(String line) {
    final out = <String>[];
    var i = 0;
    while (i < line.length) {
      while (i < line.length && (line[i] == ' ' || line[i] == '\t')) {
        i++;
      }
      if (i >= line.length) break;
      final q = line[i];
      if (q == '"' || q == "'" || q == '`') {
        final end = line.indexOf(q, i + 1);
        if (end < 0) {
          out.add(line.substring(i + 1));
          break;
        }
        out.add(line.substring(i + 1, end));
        i = end + 1;
      } else {
        var end = i;
        while (end < line.length && line[end] != ' ' && line[end] != '\t') {
          end++;
        }
        out.add(line.substring(i, end));
        i = end;
      }
    }
    return out;
  }
}
