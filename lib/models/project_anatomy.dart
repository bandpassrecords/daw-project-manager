import 'sample_reference.dart';

/// What the Project Inspector shows about one project file: read from the
/// file, never stored with the project, never synced.
///
/// One model for every DAW; each DAW's reader fills what its format gives.
/// A list that is null was not read for this DAW ("not available"); an
/// empty one was read and holds nothing.
class ProjectAnatomy {
  const ProjectAnatomy({
    required this.filePath,
    required this.fileSize,
    this.dawType,
    this.savedWith,
    this.tempo,
    this.key,
    this.timeSignature,
    this.sampleRate,
    this.bitDepth,
    this.channels,
    this.plugins = const [],
    this.pluginInstancesKnown = false,
    this.media,
    this.audioIo,
  });

  final String filePath;
  final int fileSize;

  /// The DAW's display name ("Cubase").
  final String? dawType;

  /// The version that saved the file, in full ("13.0.41").
  final String? savedWith;
  final double? tempo;
  final String? key;
  final (int, int)? timeSignature;
  final int? sampleRate;
  final int? bitDepth;

  /// Every mixer channel and folder in project order; null when this DAW's
  /// channels aren't read yet.
  final List<AnatomyChannel>? channels;

  /// Every plug-in the project uses, by name.
  final List<AnatomyPlugin> plugins;

  /// Whether [plugins] know their instances, roles and channels — false
  /// when only the names were read.
  final bool pluginInstancesKnown;

  /// The audio files the project references; null when not read.
  final List<SampleReference>? media;

  /// The studio it was saved in; null when not read.
  final AnatomyAudioIo? audioIo;
}

/// The audio interface, buses and MIDI ports a project was saved with.
class AnatomyAudioIo {
  const AnatomyAudioIo({
    this.driver,
    this.platform,
    this.inputBuses = const [],
    this.outputBuses = const [],
    this.interfaceInputs = const [],
    this.interfaceOutputs = const [],
    this.midiInputs = const [],
    this.midiOutputs = const [],
  });

  /// The audio driver ("Studio USB ASIO Driver"); null when unnamed.
  final String? driver;

  /// "Windows" or "macOS"; null when the project doesn't say.
  final String? platform;
  final List<AnatomyBus> inputBuses;
  final List<AnatomyBus> outputBuses;
  final List<String> interfaceInputs;
  final List<String> interfaceOutputs;
  final List<String> midiInputs;
  final List<String> midiOutputs;
}

/// An input or output bus and the interface ports it connects to.
class AnatomyBus {
  const AnatomyBus({required this.name, this.ports = const []});
  final String name;
  final List<String> ports;
}

enum AnatomyChannelKind { audio, instrument, midi, sampler, group, fx, folder }

/// One track or mixer channel.
class AnatomyChannel {
  const AnatomyChannel({
    required this.name,
    required this.kind,
    this.folder,
    this.output,
    this.volumeDb,
    this.faderPosition,
    this.soloed,
    this.eqBandsOn,
    this.instrument,
    this.instrumentId,
    this.instrumentPreset,
    this.inserts = const [],
    this.sends = const [],
  });

  final String name;
  final AnatomyChannelKind kind;

  /// The folder holding it, or null at the top level.
  final String? folder;

  /// Where its output goes (a group, an FX channel, an output); null when it
  /// has no channel or the destination can't be named.
  final String? output;

  /// The fader in dB, where the reader knows the scale at that point.
  final double? volumeDb;

  /// The fader's position from 0 (bottom) to 1 (top), for drawing it when
  /// [volumeDb] isn't known.
  final double? faderPosition;
  final bool? soloed;
  final int? eqBandsOn;

  /// An instrument track's instrument.
  final String? instrument;

  /// Its instrument's class id.
  final String? instrumentId;

  /// The preset its instrument had loaded.
  final String? instrumentPreset;
  final List<AnatomyInsert> inserts;
  final List<AnatomySend> sends;

  /// Whether the channel mixes others rather than holding material.
  bool get isBus =>
      kind == AnatomyChannelKind.group || kind == AnatomyChannelKind.fx;
}

class AnatomyInsert {
  const AnatomyInsert({
    required this.slot,
    required this.plugin,
    this.pluginId,
    this.deactivated,
    this.format,
    this.preset,
  });
  final int slot;
  final String plugin;
  final String? pluginId;

  /// "VST2", "VST3"…; null when not known.
  final String? format;

  /// The preset loaded in this slot.
  final String? preset;

  /// Switched off in its slot when saved.
  final bool? deactivated;
}

class AnatomySend {
  const AnatomySend({
    required this.destination,
    this.sideChainOf,
    this.levelDb,
    this.levelPosition,
    this.on = true,
    this.preFader = false,
  });

  /// The channel it sends to; null when it can't be named.
  final String? destination;

  /// The plug-in whose side-chain input this feeds, or null for a send.
  final String? sideChainOf;
  final double? levelDb;
  final double? levelPosition;
  final bool on;
  final bool preFader;
}

enum AnatomyPluginRole { instrument, effect }

/// One plug-in and where the project uses it.
class AnatomyPlugin {
  const AnatomyPlugin({
    required this.name,
    this.role,
    this.stock,
    this.instances,
    this.channels = const [],
    this.pluginId,
    this.vendor,
    this.format,
  });

  final String name;

  /// Null when only the name was read.
  final AnatomyPluginRole? role;

  /// Built into the DAW; null when not known.
  final bool? stock;

  /// How many times it is loaded; null when only the name was read.
  final int? instances;

  /// The channels it is on, in project order, each once.
  final List<String> channels;
  final String? pluginId;

  /// Its maker, where the project names one.
  final String? vendor;

  /// "VST2", "VST3"…; null when not known.
  final String? format;
}
