/// Plug-ins that come with Cubase, by the name a project stores — what the
/// Inspector counts as stock rather than third-party.
///
/// Names, not ids: a Steinberg VST3's class id says nothing about who made
/// it. The list follows Cubase 13's plug-in reference and the older ones
/// still found in projects (Cubase 4–12); a name missing here shows as
/// third-party, which is the safer mistake. Lower case, matched exactly.
const kCubaseStockPlugins = {
  // Dynamics
  'compressor', 'vintagecompressor', 'tube compressor', 'multibandcompressor',
  'multibandexpander', 'multibandenvelopeshaper', 'envelopeshaper', 'gate',
  'expander', 'limiter', 'brickwall limiter', 'maximizer', 'deesser',
  'de-esser', 'vst dynamics', 'squasher', 'magneto ii', 'magneto',
  'mid-side compressor',
  // EQ and filters
  'studioeq', 'geq-10', 'geq-30', 'frequency', 'frequency 2', 'curve eq',
  'dj-eq', 'morphfilter', 'dualfilter', 'stepfilter', 'autofilter', 'eq',
  // Delay and reverb
  'stereodelay', 'pingpongdelay', 'monodelay', 'multitap delay',
  'multitapdelay', 'modmachine', 'roomworks', 'roomworks se', 'revelation',
  'reverence', 'revx', 'reverb a', 'reverb b', 'shimmer',
  // Modulation
  'chorus', 'studiochorus', 'flanger', 'phaser', 'tremolo', 'vibrato',
  'rotary', 'metalizer', 'cloner', 'autopan', 'auto pan', 'ringmodulator',
  'stereoenhancer', 'imager', 'multiband stereo enhancer',
  // Distortion and saturation
  'amprack', 'vst amp rack', 'bitcrusher', 'datubemaker', 'distortion',
  'quadrafuzz v2', 'quadrafuzz', 'softclipper', 'vst bass amp',
  'grungelizer', 'distroyer',
  // Pitch and tools
  'pitch correct', 'octaver', 'vocalchain', 'voxengine',
  'test generator', 'tuner', 'multiscope', 'supervision', 'mixconvert v6',
  'mixconvert', 'mixerdelay', 'stereo combined panner', 'monotostereo',
  'channel strip', 'standard panner', 'input filter', 'vst multipanner',
  'loudness meter', 'noisegate', 'external fx',
  // Instruments
  'halion sonic', 'halion sonic se', 'halion se', 'halion', 'halion 7',
  'halion 6', 'groove agent se', 'groove agent', 'groove agent one',
  'retrologue', 'retrologue 2', 'padshop', 'padshop 2', 'loopmash',
  'loopmash 2', 'mystic', 'prologue', 'spector', 'embracer', 'monologue',
  'halionone', 'sampler track', 'sampler', 'iconica sketch', 'hypnotic dance',
  'trip', 'flux', 'backbone', 'anima', 'lm-7',
};

/// Whether [name] is a plug-in that comes with Cubase.
bool isCubaseStockPlugin(String name) =>
    kCubaseStockPlugins.contains(name.trim().toLowerCase());
