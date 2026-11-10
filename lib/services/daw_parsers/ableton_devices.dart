/// What an element under a track's `Devices` is, for the devices Live makes
/// itself. The element names are Live's internal ones (`Eq8`, `Compressor2`,
/// `OriginalSimpler`), not the names on its device titles, so the ones that
/// differ are listed; any other is shown with its name split into words.
enum AbletonDeviceKind { instrument, audioEffect, midiEffect, rack }

class AbletonNativeDevice {
  const AbletonNativeDevice(this.name, this.kind);
  final String name;
  final AbletonDeviceKind kind;
}

const _instrument = AbletonDeviceKind.instrument;
const _audio = AbletonDeviceKind.audioEffect;
const _midi = AbletonDeviceKind.midiEffect;
const _rack = AbletonDeviceKind.rack;

const Map<String, AbletonNativeDevice> kAbletonNativeDevices = {
  // Instruments.
  'OriginalSimpler': AbletonNativeDevice('Simpler', _instrument),
  'MultiSampler': AbletonNativeDevice('Sampler', _instrument),
  'Operator': AbletonNativeDevice('Operator', _instrument),
  'UltraAnalog': AbletonNativeDevice('Analog', _instrument),
  'Analog': AbletonNativeDevice('Analog', _instrument),
  'Wavetable': AbletonNativeDevice('Wavetable', _instrument),
  'InstrumentVector': AbletonNativeDevice('Wavetable', _instrument),
  'Drift': AbletonNativeDevice('Drift', _instrument),
  'InstrumentImpulse': AbletonNativeDevice('Impulse', _instrument),
  'Impulse': AbletonNativeDevice('Impulse', _instrument),
  'LoungeLizard': AbletonNativeDevice('Electric', _instrument),
  'Electric': AbletonNativeDevice('Electric', _instrument),
  'StringStudio': AbletonNativeDevice('Tension', _instrument),
  'Tension': AbletonNativeDevice('Tension', _instrument),
  'Collision': AbletonNativeDevice('Collision', _instrument),
  'Meld': AbletonNativeDevice('Meld', _instrument),
  // Racks (an instrument rack and a drum rack hold the instrument).
  'InstrumentGroupDevice': AbletonNativeDevice('Instrument Rack', _rack),
  'DrumGroupDevice': AbletonNativeDevice('Drum Rack', _rack),
  'AudioEffectGroupDevice': AbletonNativeDevice('Audio Effect Rack', _rack),
  'MidiEffectGroupDevice': AbletonNativeDevice('MIDI Effect Rack', _rack),
  // MIDI effects.
  'MidiArpeggiator': AbletonNativeDevice('Arpeggiator', _midi),
  'MidiChord': AbletonNativeDevice('Chord', _midi),
  'MidiScale': AbletonNativeDevice('Scale', _midi),
  'MidiPitcher': AbletonNativeDevice('Pitch', _midi),
  'MidiRandom': AbletonNativeDevice('Random', _midi),
  'MidiVelocity': AbletonNativeDevice('Velocity', _midi),
  'MidiNoteLength': AbletonNativeDevice('Note Length', _midi),
  // Audio effects whose element isn't the name Live shows.
  'Eq8': AbletonNativeDevice('EQ Eight', _audio),
  'FilterEQ3': AbletonNativeDevice('EQ Three', _audio),
  'Compressor2': AbletonNativeDevice('Compressor', _audio),
  'GlueCompressor': AbletonNativeDevice('Glue Compressor', _audio),
  'MultibandDynamics': AbletonNativeDevice('Multiband Dynamics', _audio),
  'StereoGain': AbletonNativeDevice('Utility', _audio),
  // Live 9's Simple Delay: a left and a right delay, feedback, dry/wet.
  'CrossDelay': AbletonNativeDevice('Simple Delay', _audio),
  'FilterDelay': AbletonNativeDevice('Filter Delay', _audio),
  // Live 10's Delay, which replaced Simple Delay and Ping Pong Delay.
  'Delay': AbletonNativeDevice('Delay', _audio),
  'PingPongDelay': AbletonNativeDevice('Ping Pong Delay', _audio),
  'AutoFilter': AbletonNativeDevice('Auto Filter', _audio),
  'AutoPan': AbletonNativeDevice('Auto Pan', _audio),
  'Saturator': AbletonNativeDevice('Saturator', _audio),
  'Reverb': AbletonNativeDevice('Reverb', _audio),
  'Limiter': AbletonNativeDevice('Limiter', _audio),
  'Gate': AbletonNativeDevice('Gate', _audio),
  'Erosion': AbletonNativeDevice('Erosion', _audio),
  'Amp': AbletonNativeDevice('Amp', _audio),
  'Cabinet': AbletonNativeDevice('Cabinet', _audio),
  'Redux': AbletonNativeDevice('Redux', _audio),
  'Overdrive': AbletonNativeDevice('Overdrive', _audio),
  'DynamicTube': AbletonNativeDevice('Dynamic Tube', _audio),
  'FrequencyShifter': AbletonNativeDevice('Frequency Shifter', _audio),
  'BeatRepeat': AbletonNativeDevice('Beat Repeat', _audio),
  'GrainDelay': AbletonNativeDevice('Grain Delay', _audio),
  'Hybrid': AbletonNativeDevice('Hybrid Reverb', _audio),
  'Echo': AbletonNativeDevice('Echo', _audio),
  'Chorus': AbletonNativeDevice('Chorus', _audio),
  'Chorus2': AbletonNativeDevice('Chorus-Ensemble', _audio),
  'Phaser': AbletonNativeDevice('Phaser', _audio),
  'PhaserNew': AbletonNativeDevice('Phaser-Flanger', _audio),
  'Flanger': AbletonNativeDevice('Flanger', _audio),
  'Vocoder': AbletonNativeDevice('Vocoder', _audio),
  'Looper': AbletonNativeDevice('Looper', _audio),
  'Spectrum': AbletonNativeDevice('Spectrum', _audio),
  'Tuner': AbletonNativeDevice('Tuner', _audio),
  'Corpus': AbletonNativeDevice('Corpus', _audio),
  'Resonator': AbletonNativeDevice('Resonators', _audio),
  'Roar': AbletonNativeDevice('Roar', _audio),
  'Shifter': AbletonNativeDevice('Shifter', _audio),
  'DrumBuss': AbletonNativeDevice('Drum Buss', _audio),
  'ChannelEq': AbletonNativeDevice('Channel EQ', _audio),
  'PedalDevice': AbletonNativeDevice('Pedal', _audio),
};

/// What Live calls the device that is the element [tag]: the listed name, or
/// the tag split into words ("AudioRack" → "Audio Rack").
AbletonNativeDevice abletonNativeDevice(String tag) =>
    kAbletonNativeDevices[tag] ??
    AbletonNativeDevice(
      tag.replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' '),
      AbletonDeviceKind.audioEffect,
    );

/// Whether an element under `Devices` is a third-party plug-in.
bool isAbletonPluginElement(String tag) =>
    tag == 'PluginDevice' || tag == 'AuPluginDevice';
