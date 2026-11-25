import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../models/project_stats.dart';
import '../../models/sample_reference.dart';
import 'embedded_audio_paths.dart';

/// What [StudioOneProjectParser] can read from a `.song`.
class StudioOneProjectInfo {
  const StudioOneProjectInfo({this.bpm, this.dawVersion, this.stats});
  final double? bpm;
  final String? dawVersion;
  final ProjectStats? stats;
}

/// Reads tempo, version and track counts out of a Studio One `.song`.
///
/// A `.song` is a zip of XML documents:
/// * `metainfo.xml` — `<Attribute id="Media:Tempo" value="…"/>` and
///   `id="Document:Generator"` (`"Studio One/6.5.1.96553"`).
/// * `Song/song.xml` — the track list: `MediaTrack` elements whose
///   `mediaType` is `Audio` or `Music` (instrument tracks), and
///   `FolderTrack`s.
/// * `Devices/audiomixer.xml` — bus and FX channels (`AudioBusChannel`,
///   `AudioEffectChannel`).
///
/// Implemented from the format's public descriptions, without a real file
/// to check against, so every read is defensive: a missing entry or an
/// unexpected shape costs that one value, never the others. Plug-ins and
/// MIDI clips aren't read yet.
class StudioOneProjectParser {
  StudioOneProjectParser(this.bytes);

  final Uint8List bytes;

  StudioOneProjectInfo read() {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return const StudioOneProjectInfo();
    }

    XmlDocument? doc(String path) {
      final file = archive.findFile(path);
      if (file == null) return null;
      try {
        return XmlDocument.parse(utf8.decode(file.content, allowMalformed: true));
      } catch (_) {
        return null;
      }
    }

    double? bpm;
    String? version;
    final meta = doc('metainfo.xml');
    if (meta != null) {
      for (final a in meta.findAllElements('Attribute')) {
        final id = a.getAttribute('id');
        final value = a.getAttribute('value');
        if (value == null) continue;
        if (id == 'Media:Tempo') {
          final v = double.tryParse(value);
          if (v != null && v > 0 && v < 1000) bpm = v;
        } else if (id == 'Document:Generator') {
          final m = RegExp(r'(\d+)\.(\d+)').firstMatch(value);
          if (m != null) version = '${m.group(1)}.${m.group(2)}';
        }
      }
    }

    ProjectStats? stats;
    final song = doc('Song/song.xml');
    if (song != null) {
      var audio = 0, instrument = 0, folder = 0, bus = 0;
      for (final e in song.descendantElements) {
        switch (e.name.local) {
          case 'MediaTrack':
            switch (e.getAttribute('mediaType')) {
              case 'Audio':
                audio++;
              case 'Music':
                instrument++;
            }
          case 'FolderTrack':
            folder++;
        }
      }
      final mixer = doc('Devices/audiomixer.xml');
      if (mixer != null) {
        for (final e in mixer.descendantElements) {
          final n = e.name.local;
          // Real songs (Studio One 6 and 7) call a bus AudioGroupChannel;
          // AudioBusChannel is what the format's descriptions said.
          if (n == 'AudioGroupChannel' ||
              n == 'AudioBusChannel' ||
              n == 'AudioEffectChannel') {
            bus++;
          }
        }
      }
      stats = ProjectStats(
        audioTracks: audio,
        instrumentTracks: instrument,
        folderTracks: folder,
        busTracks: bus,
      );
    }

    return StudioOneProjectInfo(bpm: bpm, dawVersion: version, stats: stats);
  }

  /// The console: every channel with its fader, pan, mute, solo, output,
  /// inserts and sends, the instruments that play into it, and the song's
  /// sample rate, bit depth and time signature — what the Project
  /// Inspector shows (#228). Null when the song has no console.
  ///
  /// Read from real songs (Studio One 6.6 and 7):
  /// * `metainfo.xml`: `Media:SampleRate`, `Media:BitDepth`,
  ///   `Media:TimeSignatureNumerator`/`Denominator`.
  /// * `Devices/audiomixer.xml`: `ChannelGroup`s of `AudioTrackChannel`,
  ///   `AudioSynthChannel` (an instrument's output), `AudioGroupChannel`
  ///   (a bus), `AudioEffectChannel`, `AudioVCAChannel` and
  ///   `AudioOutputChannel`; input channels aren't the mix's. A channel's
  ///   `label` is its name, `gain` a linear gain, `pan` 0 (left) to 1, and
  ///   its `Connection x:id="destination"` names the channel it feeds by
  ///   its UID (`{…}/Input`). `Inserts` (and an output's
  ///   `PostFaderInserts`) hold one `Attributes` per plug-in — `bypass`,
  ///   `deviceData` (the instance's name), `ghostData/classInfo` (the
  ///   plug-in's name, class id and `subCategory`: `(Native)/…` for
  ///   PreSonus's own, `VST2`, `VST3/…`, `AU…`) and `Presets` (`pname`).
  ///   `Sends` hold `level` (a gain, as the fader's), `pan`, `prefader`,
  ///   `bypass` and a destination.
  /// * `Devices/audiosynthfolder.xml`: each instrument, and the synth
  ///   channels it plays into (`synthChannels`).
  StudioOneConsole? readConsole() {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return null;
    }
    XmlDocument? doc(String path) {
      final file = archive.findFile(path);
      if (file == null) return null;
      try {
        return XmlDocument.parse(
          utf8.decode(file.content, allowMalformed: true),
        );
      } catch (_) {
        return null;
      }
    }

    final mixer = doc('Devices/audiomixer.xml');
    if (mixer == null) return null;

    final meta = <String, String>{};
    for (final a in doc('metainfo.xml')?.findAllElements('Attribute') ??
        const <XmlElement>[]) {
      final id = a.getAttribute('id'), value = a.getAttribute('value');
      if (id != null && value != null) meta[id] = value;
    }
    int? metaInt(String id) => int.tryParse(meta[id] ?? '');

    // Instruments, by the synth channel each plays into.
    final instruments = <String, StudioOnePlugin>{};
    for (final inst
        in doc('Devices/audiosynthfolder.xml')?.rootElement.childElements ??
            const <XmlElement>[]) {
      final plugin = _plugin(inst);
      if (plugin == null) continue;
      for (final list in inst.childElements.where(
        (e) => _xid(e) == 'synthChannels',
      )) {
        for (final uid in list.findElements('UID')) {
          final id = uid.getAttribute('uid');
          if (id != null) instruments[id.toUpperCase()] = plugin;
        }
      }
    }

    const kinds = {
      'AudioTrackChannel': StudioOneChannelKind.audio,
      'AudioSynthChannel': StudioOneChannelKind.instrument,
      'AudioGroupChannel': StudioOneChannelKind.group,
      'AudioBusChannel': StudioOneChannelKind.group,
      'AudioEffectChannel': StudioOneChannelKind.fx,
      'AudioVCAChannel': StudioOneChannelKind.vca,
      'AudioOutputChannel': StudioOneChannelKind.output,
    };
    final elements = [
      for (final e in mixer.findAllElements('*'))
        if (kinds.containsKey(e.name.local)) e,
    ];
    final labels = <String, String>{
      for (final e in elements) ?_uidOf(e): _label(e),
    };
    String? destination(XmlElement e) {
      final c = e.childElements
          .where((c) => c.name.local == 'Connection' && _xid(c) == 'destination')
          .firstOrNull;
      if (c == null) return null;
      final target = RegExp(
        r'\{[0-9A-Fa-f-]+\}',
      ).firstMatch(c.getAttribute('objectID') ?? '')?.group(0)?.toUpperCase();
      final name = labels[target] ?? c.getAttribute('friendlyName');
      return name == null || name.isEmpty ? null : name;
    }

    final channels = <StudioOneChannel>[];
    for (final e in elements) {
      final kind = kinds[e.name.local]!;
      List<StudioOnePlugin> pluginsIn(String xid) => [
        for (final list in e.childElements.where((c) => _xid(c) == xid))
          for (final slot in list.childElements) ?_plugin(slot),
      ];
      channels.add(
        StudioOneChannel(
          name: _label(e),
          kind: kind,
          gain: double.tryParse(e.getAttribute('gain') ?? ''),
          pan: double.tryParse(e.getAttribute('pan') ?? ''),
          muted: _flag(e.getAttribute('mute')),
          soloed: _flag(e.getAttribute('solo')),
          destination: destination(e),
          instrument: kind == StudioOneChannelKind.instrument
              ? instruments[_uidOf(e)]
              : null,
          inserts: [...pluginsIn('Inserts'), ...pluginsIn('PostFaderInserts')],
          sends: [
            for (final list in e.childElements.where((c) => _xid(c) == 'Sends'))
              for (final s in list.childElements)
                if (s.getAttribute('level') != null)
                  StudioOneSend(
                    destination: destination(s),
                    level: double.tryParse(s.getAttribute('level') ?? ''),
                    preFader: _flag(s.getAttribute('prefader')) ?? false,
                    bypassed: _flag(s.getAttribute('bypass')) ?? false,
                  ),
          ],
        ),
      );
    }

    final n = metaInt('Media:TimeSignatureNumerator');
    final d = metaInt('Media:TimeSignatureDenominator');
    return StudioOneConsole(
      channels: channels,
      sampleRate: switch (metaInt('Media:SampleRate')) {
        final r? when r > 0 => r,
        _ => null,
      },
      bitDepth: switch (metaInt('Media:BitDepth')) {
        final b? when b > 0 => b,
        _ => null,
      },
      timeSignature: n != null && d != null && n > 0 && d > 0 ? (n, d) : null,
    );
  }

  static String? _xid(XmlElement e) => e.getAttribute('x:id');

  static bool? _flag(String? v) => v == null ? null : v == '1';

  static String _label(XmlElement e) {
    final label = e.getAttribute('label')?.trim();
    return label != null && label.isNotEmpty
        ? label
        : (e.getAttribute('name') ?? '');
  }

  /// A channel's own UID, upper case: what connections point at.
  static String? _uidOf(XmlElement e) => e.childElements
      .where((c) => c.name.local == 'UID' && _xid(c) == 'uniqueID')
      .firstOrNull
      ?.getAttribute('uid')
      ?.toUpperCase();

  /// A plug-in in an insert slot or the instrument folder; null for what
  /// isn't one (a slot list's presets, the combinator).
  static StudioOnePlugin? _plugin(XmlElement slot) {
    final classId = slot.childElements
        .where((c) => c.name.local == 'UID' && _xid(c) == 'deviceClassID')
        .firstOrNull
        ?.getAttribute('uid');
    if (classId == null) return null;
    XmlElement? child(String xid, [XmlElement? of]) => (of ?? slot)
        .childElements
        .where((c) => _xid(c) == xid)
        .firstOrNull;
    final instance = child('deviceData')?.getAttribute('name')?.trim();
    final ghost = child('ghostData');
    final info = ghost == null ? null : child('classInfo', ghost);
    final name = info?.getAttribute('name')?.trim();
    final sub = info?.getAttribute('subCategory') ?? '';
    final shown = name != null && name.isNotEmpty ? name : instance;
    if (shown == null || shown.isEmpty) return null;
    final preset = child('Presets')?.getAttribute('pname')?.trim();
    return StudioOnePlugin(
      name: shown,
      classId: classId.replaceAll(RegExp(r'[{}-]'), '').toUpperCase(),
      format: sub.startsWith('VST3')
          ? 'VST3'
          : sub.startsWith('VST2') || sub == 'VST'
          ? 'VST2'
          : sub.startsWith('AU')
          ? 'AU'
          : sub.startsWith('CLAP')
          ? 'CLAP'
          : null,
      native: sub.startsWith('(Native)') ? true : (info == null ? null : false),
      isInstrument: info?.getAttribute('category') == 'AudioSynth',
      preset: preset == null || preset.isEmpty ? null : preset,
      bypassed: _flag(slot.getAttribute('bypass')) ?? false,
    );
  }

  /// Every audio file the song references.
  ///
  /// * `Song/mediapool.xml` lists each one once as an `AudioClip` whose
  ///   `Url` is a `file:///` URL (absolute, percent-encoded). Studio One
  ///   keeps a song's own audio in its `Media` folder, which is tried too.
  /// * Instrument and effect state is stored as files under `Presets/`
  ///   (Sample One, Impact XT, third-party `.fxb`s) and searched for
  ///   absolute paths.
  List<SampleReference> readSampleReferences() {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return const [];
    }
    final refs = <SampleReference>[];
    final pool = archive.findFile('Song/mediapool.xml');
    if (pool != null) {
      try {
        final doc = XmlDocument.parse(
          utf8.decode(pool.content, allowMalformed: true),
        );
        for (final clip in doc.findAllElements('AudioClip')) {
          for (final url in clip.findElements('Url')) {
            final path = _filePathOfUrl(url.getAttribute('url'));
            if (path == null || !isSampleAudioFile(path)) continue;
            final name = sampleFileNameOf(path);
            refs.add(SampleReference(
              fileName: name,
              candidates: [path, 'Media/$name'],
            ));
          }
        }
      } catch (_) {
        // An unreadable pool costs the pool, not the presets.
      }
    }
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('Presets/')) continue;
      for (final path in findEmbeddedAudioPaths(file.content)) {
        refs.add(SampleReference(
          fileName: sampleFileNameOf(path),
          candidates: [path],
          use: file.name.startsWith('Presets/Synths/')
              ? SampleUse.sampler
              : SampleUse.plugin,
        ));
      }
    }
    return refs;
  }

  /// `file:///G:/Pack/Kick%20(1).wav` → `G:/Pack/Kick (1).wav`;
  /// `file:///Users/me/kick.wav` → `/Users/me/kick.wav`.
  static String? _filePathOfUrl(String? url) {
    if (url == null || !url.startsWith('file:')) return null;
    var rest = url.substring(5);
    while (rest.startsWith('//')) {
      rest = rest.substring(1);
    }
    String decoded;
    try {
      decoded = Uri.decodeFull(rest);
    } catch (_) {
      decoded = rest;
    }
    // "/G:/…" is a Windows path behind the URL's leading slash.
    if (RegExp(r'^/[A-Za-z]:[\\/]').hasMatch(decoded)) {
      decoded = decoded.substring(1);
    }
    return decoded;
  }
}

enum StudioOneChannelKind { audio, instrument, group, fx, vca, output }

/// A plug-in on the console or in the instrument folder.
class StudioOnePlugin {
  const StudioOnePlugin({
    required this.name,
    this.classId,
    this.format,
    this.native,
    this.isInstrument = false,
    this.preset,
    this.bypassed = false,
  });

  final String name;

  /// Its class id, 32 hex digits.
  final String? classId;

  /// `VST2`, `VST3`, `AU`, `CLAP`; null for PreSonus's own.
  final String? format;

  /// PreSonus's own (`(Native)/…`); null when the song doesn't say.
  final bool? native;
  final bool isInstrument;

  /// The preset loaded, as Studio One names it.
  final String? preset;
  final bool bypassed;
}

class StudioOneSend {
  const StudioOneSend({
    this.destination,
    this.level,
    this.preFader = false,
    this.bypassed = false,
  });

  final String? destination;

  /// A linear gain, as a channel's fader is.
  final double? level;
  final bool preFader;
  final bool bypassed;
}

class StudioOneChannel {
  const StudioOneChannel({
    required this.name,
    required this.kind,
    this.gain,
    this.pan,
    this.muted,
    this.soloed,
    this.destination,
    this.instrument,
    this.inserts = const [],
    this.sends = const [],
  });

  final String name;
  final StudioOneChannelKind kind;

  /// The fader as a linear gain: 1 is 0 dB.
  final double? gain;

  /// 0 left, 0.5 centre, 1 right.
  final double? pan;
  final bool? muted;
  final bool? soloed;

  /// The channel it feeds, by its name.
  final String? destination;

  /// The instrument playing into an instrument channel.
  final StudioOnePlugin? instrument;
  final List<StudioOnePlugin> inserts;
  final List<StudioOneSend> sends;
}

class StudioOneConsole {
  const StudioOneConsole({
    required this.channels,
    this.sampleRate,
    this.bitDepth,
    this.timeSignature,
  });

  final List<StudioOneChannel> channels;
  final int? sampleRate;
  final int? bitDepth;
  final (int, int)? timeSignature;
}
