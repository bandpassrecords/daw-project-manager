import 'dart:math' as math;
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../models/midi_clip.dart';
import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import 'ableton_devices.dart';
import 'embedded_audio_paths.dart';

enum AbletonTrackKind { audio, midi, group, returnTrack, master }

/// One track of a Live set as saved: what the Inspector shows of a channel.
class AbletonTrack {
  const AbletonTrack({
    required this.name,
    required this.kind,
    this.group,
    this.outputTarget,
    this.outputUpper,
    this.outputLower,
    this.volume,
    this.pan,
    this.active,
    this.soloed,
    this.sends = const [],
    this.devices = const [],
  });

  final String name;
  final AbletonTrackKind kind;

  /// The group track holding it.
  final String? group;

  /// Where its audio goes: Live's route (`AudioOut/Master`,
  /// `AudioOut/GroupTrack`, `AudioOut/External/S0`) and the two lines it
  /// shows for it ("Ext. Out", "1/2").
  final String? outputTarget;
  final String? outputUpper;
  final String? outputLower;

  /// The fader as a linear gain: 1 is 0 dB, 1.995 is +6 dB.
  final double? volume;

  /// -1 (left) to 1 (right).
  final double? pan;

  /// The track activator; false is a muted track.
  final bool? active;
  final bool? soloed;
  final List<AbletonSend> sends;
  final List<AbletonDevice> devices;
}

/// A track's send to one return track.
class AbletonSend {
  const AbletonSend({
    required this.destination,
    this.level,
    this.active = true,
    this.preFader = false,
  });
  final String destination;

  /// Linear gain; 0.000316 (−70 dB) is as far down as the knob goes.
  final double? level;
  final bool active;
  final bool preFader;
}

/// A device on a track: one Live makes, or a plug-in.
class AbletonDevice {
  const AbletonDevice({
    required this.tag,
    required this.name,
    required this.kind,
    required this.isPlugin,
    this.userName,
    this.format,
    this.pluginId,
    this.vendor,
    this.on,
    this.nested = const [],
  });

  /// The element's name in the set (`Eq8`, `PluginDevice`).
  final String tag;

  /// What Live or the plug-in calls it ("EQ Eight", "Sylenth1").
  final String name;

  /// What the user renamed it to, if they did.
  final String? userName;
  final AbletonDeviceKind kind;
  final bool isPlugin;

  /// "VST2", "VST3", "AU".
  final String? format;
  final String? pluginId;
  final String? vendor;

  /// Switched on; false is a bypassed device.
  final bool? on;

  /// A rack's devices, every branch's, in order.
  final List<AbletonDevice> nested;
}

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

  XmlElement? get _liveSet => document.rootElement.getElement('LiveSet');

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

  /// The set's time signature, from the master track's mixer. Live stores it
  /// as one number: `numerator − 1 + 99 × log2(denominator)` (201 is 4/4).
  (int, int)? readTimeSignature() {
    final master = _liveSet?.getElement('MasterTrack');
    final raw = _param(
      (master == null ? null : _chainOf(master))
          ?.getElement('Mixer')
          ?.getElement('TimeSignature'),
    );
    final index = int.tryParse(raw ?? '');
    if (index == null || index < 0) return null;
    final denominator = 1 << (index ~/ 99);
    if (denominator > 16) return null;
    return (index % 99 + 1, denominator);
  }

  /// Every track in the set — tracks, groups, returns, then the master — with
  /// the mixer settings and devices Live saved for it.
  ///
  /// A value Live keeps as an automatable parameter is its `Manual` (the
  /// current setting); Live 8 had none, and keeps the value of the first
  /// automation event instead — [_param] reads both.
  List<AbletonTrack> readTracks() {
    final liveSet = _liveSet;
    if (liveSet == null) return const [];
    final tracks =
        liveSet.getElement('Tracks')?.childElements.toList() ??
        const <XmlElement>[];
    final returns = [
      for (final t in tracks)
        if (t.name.local == 'ReturnTrack') _trackName(t) ?? '',
    ];
    final preFader = [
      for (final e
          in liveSet.getElement('SendsPre')?.childElements ??
              const <XmlElement>[])
        _value(e) == 'true',
    ];
    final names = <String, String>{
      for (final t in tracks)
        if (t.getAttribute('Id') != null)
          t.getAttribute('Id')!: _trackName(t) ?? '',
    };

    AbletonTrack read(XmlElement t, AbletonTrackKind kind) {
      final chain = _chainOf(t);
      final mixer = chain?.getElement('Mixer');
      final routing = chain?.getElement('AudioOutputRouting');
      final groupId = _value(t.getElement('TrackGroupId'));

      final sends = <AbletonSend>[];
      if (kind != AbletonTrackKind.returnTrack &&
          kind != AbletonTrackKind.master) {
        final holders =
            mixer?.getElement('Sends')?.childElements.toList() ??
            const <XmlElement>[];
        for (var i = 0; i < holders.length && i < returns.length; i++) {
          sends.add(
            AbletonSend(
              destination: returns[i],
              level: double.tryParse(
                _param(holders[i].getElement('Send')) ?? '',
              ),
              active: _value(holders[i].getElement('Active')) != 'false',
              preFader: i < preFader.length && preFader[i],
            ),
          );
        }
      }

      return AbletonTrack(
        name: _trackName(t) ?? '',
        kind: kind,
        group: groupId != null && groupId != '-1' ? names[groupId] : null,
        outputTarget: _value(routing?.getElement('Target')),
        outputUpper: _value(routing?.getElement('UpperDisplayString')),
        outputLower: _value(routing?.getElement('LowerDisplayString')),
        volume: double.tryParse(_param(mixer?.getElement('Volume')) ?? ''),
        pan: double.tryParse(_param(mixer?.getElement('Pan')) ?? ''),
        // The track activator: off means the track is muted.
        active: switch (_param(mixer?.getElement('Speaker'))) {
          'true' => true,
          'false' => false,
          _ => null,
        },
        soloed: switch (_value(mixer?.getElement('SoloSink'))) {
          'true' => true,
          'false' => false,
          _ => null,
        },
        sends: sends,
        devices: _devicesOf(
          chain?.getElement('DeviceChain')?.getElement('Devices'),
        ),
      );
    }

    return [
      for (final t in tracks)
        if (switch (t.name.local) {
              'AudioTrack' => AbletonTrackKind.audio,
              'MidiTrack' => AbletonTrackKind.midi,
              'GroupTrack' => AbletonTrackKind.group,
              'ReturnTrack' => AbletonTrackKind.returnTrack,
              _ => null,
            }
            case final kind?)
          read(t, kind),
      if (liveSet.getElement('MasterTrack') case final master?)
        read(master, AbletonTrackKind.master),
    ];
  }

  List<AbletonDevice> _devicesOf(XmlElement? devices) {
    if (devices == null) return const [];
    return [
      for (final d in devices.childElements)
        if (d.getAttribute('Id') != null || d.childElements.isNotEmpty)
          _device(d),
    ];
  }

  AbletonDevice _device(XmlElement d) {
    final tag = d.name.local;
    final userName = _value(d.getElement('UserName'))?.trim();
    final on = switch (_param(d.getElement('On'))) {
      'true' => true,
      'false' => false,
      _ => null,
    };
    final nested = [
      for (final list in _deviceListsUnder(d)) ..._devicesOf(list),
    ];

    if (isAbletonPluginElement(tag)) {
      final desc = d.getElement('PluginDesc')?.childElements.firstOrNull;
      final info = _pluginInfo(desc);
      return AbletonDevice(
        tag: tag,
        name: info.name ?? userName ?? tag,
        userName: userName == null || userName.isEmpty ? null : userName,
        kind: info.isInstrument == true
            ? AbletonDeviceKind.instrument
            : AbletonDeviceKind.audioEffect,
        isPlugin: true,
        format: info.format,
        pluginId: info.id,
        vendor: info.vendor,
        on: on,
        nested: nested,
      );
    }
    final native = abletonNativeDevice(tag);
    return AbletonDevice(
      tag: tag,
      name: native.name,
      userName: userName == null || userName.isEmpty ? null : userName,
      kind: native.kind,
      isPlugin: false,
      on: on,
      nested: nested,
    );
  }

  /// The `Devices` lists directly inside a rack's branches (not the lists of
  /// racks nested further in, which their own device reads).
  Iterable<XmlElement> _deviceListsUnder(XmlElement e) sync* {
    for (final c in e.childElements) {
      if (c.name.local == 'Devices') {
        yield c;
      } else {
        yield* _deviceListsUnder(c);
      }
    }
  }

  /// Name, format, class id and kind of one `PluginDesc` child
  /// (`VstPluginInfo`, `Vst3PluginInfo`, `AuPluginInfo`…).
  ///
  /// A VST2's category is VST's (2 is a synth); a VST3's `DeviceType` is 1
  /// for an instrument and 2 for an effect; an Audio Unit says it with its
  /// component type (`aumu`). Live names no maker for VST2 or VST3.
  ({
    String? name,
    String? format,
    String? id,
    String? vendor,
    bool? isInstrument,
  })
  _pluginInfo(XmlElement? info) {
    if (info == null) {
      return (
        name: null,
        format: null,
        id: null,
        vendor: null,
        isInstrument: null,
      );
    }
    final tag = info.name.local;
    final name =
        _value(info.getElement('Name')) ?? _value(info.getElement('PlugName'));
    switch (tag) {
      case 'VstPluginInfo':
        final id = int.tryParse(_value(info.getElement('UniqueId')) ?? '');
        final category = int.tryParse(
          _value(info.getElement('Category')) ?? '',
        );
        return (
          name: name,
          format: 'VST2',
          id: id == null
              ? null
              : (id & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0'),
          vendor: null,
          isInstrument: category == null ? null : category == 2,
        );
      case 'Vst3PluginInfo':
        final fields = [
          for (var i = 0; i < 4; i++)
            int.tryParse(
              _value(info.getElement('Uid')?.getElement('Fields.$i')) ?? '',
            ),
        ];
        final deviceType = int.tryParse(
          _value(info.getElement('DeviceType')) ?? '',
        );
        return (
          name: name,
          format: 'VST3',
          id: fields.contains(null)
              ? null
              : [
                  for (final f in fields)
                    (f! & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0'),
                ].join().toUpperCase(),
          vendor: null,
          isInstrument: deviceType == null ? null : deviceType == 1,
        );
      case 'AuPluginInfo':
        final type = _value(info.getElement('ComponentType'));
        return (
          name: name,
          format: 'AU',
          id: null,
          vendor: _value(info.getElement('Manufacturer')),
          // 'aumu' as a number: 0x61756D75.
          isInstrument: type == null ? null : int.tryParse(type) == 0x61756D75,
        );
      default:
        return (
          name: name,
          format: tag.replaceAll('PluginInfo', '').toUpperCase(),
          id: null,
          vendor: null,
          isInstrument: null,
        );
    }
  }

  /// A track's routing, mixer and devices: its `DeviceChain`, or — for
  /// Live 8's master track — its `MasterChain`, which is laid out the same.
  static XmlElement? _chainOf(XmlElement track) =>
      track.getElement('DeviceChain') ?? track.getElement('MasterChain');

  static String? _trackName(XmlElement track) {
    final name = track.getElement('Name');
    final user = _value(name?.getElement('UserName'));
    if (user != null && user.isNotEmpty) return user;
    return _value(name?.getElement('EffectiveName'));
  }

  /// A parameter's current value: its `Manual`, else (Live 8) the value of
  /// its first automation event, the one at the start of time.
  static String? _param(XmlElement? e) {
    if (e == null) return null;
    final manual = e.getElement('Manual');
    if (manual != null) return _value(manual);
    final events = e.getElement('ArrangerAutomation')?.getElement('Events');
    XmlElement? first;
    var firstTime = double.infinity;
    for (final event in events?.childElements ?? const <XmlElement>[]) {
      final time = double.tryParse(event.getAttribute('Time') ?? '');
      if (time != null && time < firstTime) {
        first = event;
        firstTime = time;
      }
    }
    return _value(first);
  }

  List<String> readPluginNames() {
    final names = <String>[];
    for (final desc in document.findAllElements('PluginDesc')) {
      for (final info in desc.childElements) {
        final name =
            _value(info.getElement('Name')) ??
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
      final events =
          keyTrack.getElement('Notes')?.childElements ?? const <XmlElement>[];
      for (final e in events) {
        if (e.name.local != 'MidiNoteEvent') continue;
        if (e.getAttribute('IsEnabled') == 'false') continue;
        final time = double.tryParse(e.getAttribute('Time') ?? '');
        final duration = double.tryParse(e.getAttribute('Duration') ?? '');
        final velocity = double.tryParse(e.getAttribute('Velocity') ?? '');
        if (time == null || duration == null) continue;
        source.add(
          MidiNote(
            startTick: _ticks(time),
            lengthTicks: _ticks(duration) < 1 ? 1 : _ticks(duration),
            pitch: pitch,
            velocity: (velocity ?? 100).round().clamp(1, 127),
          ),
        );
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
      final pointee = _value(
        envelope.getElement('EnvelopeTarget')?.getElement('PointeeId'),
      );
      final target = targets[pointee];
      if (target == null) continue;
      final (kind, number) = target;
      final points = <(double, double)>[];
      for (final e
          in envelope
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
      if (time < 0 ||
          nextTime <= time ||
          midiValue(nextValue) == midiValue(value)) {
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

  /// Every audio file the set references: audio clips, and the samples in
  /// Simpler, Sampler, Impulse and Drum Rack pads — all of which hold a
  /// `SampleRef/FileRef` — plus paths a third-party plug-in keeps in its
  /// saved state (`Buffer`, hex).
  ///
  /// A `FileRef` names the file several ways, all kept as candidates:
  /// * Live 11+: `Path` (absolute) and `RelativePath Value` (from the set's
  ///   folder, file name included).
  /// * Live 9/10: `RelativePath` as `RelativePathElement Dir`s (an empty
  ///   `Dir` is `..`) plus `Name`, and `Data`, hex of the absolute path as
  ///   UTF-16LE on Windows (a macOS alias record elsewhere, which isn't a
  ///   path and is skipped).
  ///
  /// Live files what it makes under the project's `Samples` folder, which is
  /// what [SampleReference.kind] says: `Recorded`, `Processed` (consolidate,
  /// freeze, crop, reverse) and `Imported`.
  List<SampleReference> readSampleReferences() {
    final refs = <SampleReference>[];
    for (final sampleRef in document.findAllElements('SampleRef')) {
      final fileRef = sampleRef.getElement('FileRef');
      if (fileRef == null) continue;
      final inClip = sampleRef.ancestorElements.any(
        (a) => a.name.local == 'AudioClip',
      );
      final ref = _sampleReference(
        fileRef,
        inClip ? SampleUse.audio : SampleUse.sampler,
      );
      if (ref != null) refs.add(ref);
    }
    for (final buffer in document.findAllElements('Buffer')) {
      final bytes = _hexBytes(buffer.innerText);
      if (bytes == null) continue;
      for (final path in findEmbeddedAudioPaths(bytes)) {
        refs.add(
          SampleReference(
            fileName: sampleFileNameOf(path),
            candidates: [path],
            use: SampleUse.plugin,
          ),
        );
      }
    }
    return refs;
  }

  SampleReference? _sampleReference(XmlElement fileRef, SampleUse use) {
    final absolute = _value(fileRef.getElement('Path'));
    final relativeElement = fileRef.getElement('RelativePath');
    final relativeValue = _value(relativeElement);
    final dirs = [
      for (final e
          in relativeElement?.findElements('RelativePathElement') ??
              const <XmlElement>[])
        e.getAttribute('Dir') ?? '',
    ];
    var name = _value(fileRef.getElement('Name'));
    if (name == null || name.isEmpty) {
      final from = absolute ?? relativeValue;
      if (from == null || from.isEmpty) return null;
      name = sampleFileNameOf(from);
    }
    if (!isSampleAudioFile(name)) return null;

    String? relative;
    if (relativeValue != null && relativeValue.isNotEmpty) {
      relative = relativeValue;
    } else if (dirs.isNotEmpty) {
      relative = [for (final d in dirs) d.isEmpty ? '..' : d, name].join('/');
    }

    String? fromData;
    final data = _hexBytes(fileRef.getElement('Data')?.innerText ?? '');
    if (data != null && data.length >= 8 && data.length.isEven) {
      final text = String.fromCharCodes([
        for (var i = 0; i + 1 < data.length; i += 2)
          data[i] | (data[i + 1] << 8),
      ]).replaceAll('\u0000', '');
      if (RegExp(r'^([A-Za-z]:[\\/]|\\\\)').hasMatch(text) &&
          text.toLowerCase().endsWith(name.toLowerCase())) {
        fromData = text;
      }
    }

    final within = (relative ?? '').replaceAll('\\', '/').toLowerCase();
    final SampleKind? kind = within.startsWith('samples/recorded/')
        ? SampleKind.recorded
        : within.startsWith('samples/processed/')
        ? SampleKind.processed
        : within.startsWith('samples/imported/')
        ? SampleKind.imported
        : null;

    final size = int.tryParse(
      _value(fileRef.getElement('OriginalFileSize')) ??
          _value(fileRef.getElement('SearchHint')?.getElement('FileSize')) ??
          '',
    );

    return SampleReference(
      fileName: name,
      candidates: [
        if (absolute != null && absolute.isNotEmpty) absolute,
        ?fromData,
        ?relative,
      ],
      use: use,
      kind: kind,
      sizeBytes: size != null && size > 0 ? size : null,
    );
  }

  /// [text] as hex digits (whitespace ignored), or null when it isn't.
  static Uint8List? _hexBytes(String text) {
    final hex = text.replaceAll(RegExp(r'\s+'), '');
    if (hex.isEmpty || hex.length.isOdd) return null;
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final v = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      if (v == null) return null;
      out[i] = v;
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
