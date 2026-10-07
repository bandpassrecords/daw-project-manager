import '../../models/midi_clip.dart';

/// The sounds the built-in preview synth can play a clip with.
///
/// Rough sketches of each family, not samples — enough to tell a bassline
/// from a pad from a hi-hat pattern while auditioning.
///
/// There used to be a plain `synth` voice too, the fallback. It sounded all
/// but the same as [bass] and was retired; a stored pick of it no longer
/// names a voice and is inferred again, like any name this build lacks.
enum SynthVoice {
  lead,
  bass,
  pad,
  pluck,
  keys,
  organ,
  strings,
  brass,
  bell,

  /// General MIDI drum map: each pitch is its own drum.
  drumKit,
  kick,
  snare,
  clap,
  hiHat,
  percussion;

  bool get isDrum => index >= SynthVoice.drumKit.index;
}

/// How names identify a voice, checked in this order — drums first, because
/// "bass drum" and "kick bass" are drums, not basses.
///
/// `words` must be a whole word of the name ("ep", "sub", "arp"); `parts`
/// may appear anywhere in it, glued to other words ("Kick 3", "Bassline",
/// "MainLead"). Short or common fragments are words on purpose: as parts,
/// "sub" would read into "Subtle", "arp" into "Sharp", "ch" into "Ch 1".
const _rules = <({SynthVoice voice, List<String> words, List<String> parts})>[
  (voice: SynthVoice.kick, words: ['kik', 'bd'], parts: ['kick', 'bassdrum']),
  (voice: SynthVoice.snare, words: ['snr', 'sd', 'rim', 'rimshot'], parts: ['snare']),
  (voice: SynthVoice.clap, words: ['snap', 'snaps'], parts: ['clap']),
  (voice: SynthVoice.hiHat, words: ['hat', 'hats', 'hh', 'ride', 'crash', 'tamb'], parts: ['hihat', 'cymbal', 'shaker', 'tambourine']),
  (voice: SynthVoice.percussion, words: ['perc', 'percs', 'tom', 'toms', 'clave'], parts: ['percussion', 'conga', 'bongo', 'cowbell']),
  (voice: SynthVoice.drumKit, words: ['kit', 'beat', 'beats', 'groove'], parts: ['drum']),
  (voice: SynthVoice.bass, words: ['sub', 'reese', '808'], parts: ['bass']),
  (voice: SynthVoice.pad, words: ['pad', 'pads', 'atmo', 'drone', 'swell'], parts: ['ambient', 'ambience', 'texture', 'choir']),
  (voice: SynthVoice.pluck, words: ['arp', 'seq', 'stab', 'stabs'], parts: ['pluck', 'arpegg', 'sequence']),
  (voice: SynthVoice.keys, words: ['keys', 'key', 'ep', 'clav', 'chord', 'chords'], parts: ['piano', 'rhodes', 'wurli', 'keyscape']),
  (voice: SynthVoice.organ, words: ['b3'], parts: ['organ', 'hammond']),
  (voice: SynthVoice.strings, words: ['orch'], parts: ['string', 'violin', 'viola', 'cello', 'orchestr', 'ensemble']),
  (voice: SynthVoice.brass, words: ['horn', 'horns', 'sax', 'tuba'], parts: ['brass', 'trumpet', 'trombone', 'saxophone']),
  (voice: SynthVoice.bell, words: ['bell', 'bells', 'vibes'], parts: ['mallet', 'marimba', 'glock', 'vibraphone', 'kalimba', 'xylo']),
  (voice: SynthVoice.lead, words: ['ld', 'solo', 'hook', 'saw'], parts: ['lead', 'melody', 'topline']),
];

/// Splits a name into lowercase words: on anything that isn't a letter or
/// digit, and on camelCase / letter-digit boundaries ("MainLead2" →
/// main, lead, 2).
List<String> _words(String name) {
  final spaced = name
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'([A-Za-z])(\d)'), (m) => '${m[1]} ${m[2]}');
  return spaced
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();
}

/// The voice a name points at, or null if it says nothing recognisable.
SynthVoice? voiceFromName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final words = _words(name);
  final joined = words.join();
  for (final rule in _rules) {
    if (rule.words.any(words.contains) || rule.parts.any(joined.contains)) {
      return rule.voice;
    }
  }
  return null;
}

/// Picks the voice a clip most likely wants: its track's name first (that is
/// what usually says what a part is for), then the clip's own name. Failing
/// both, a clip that sits entirely low is played as a bass, and anything
/// else on [SynthVoice.keys], the most neutral of the rest.
SynthVoice inferSynthVoice(MidiClip clip) {
  final fromName = voiceFromName(clip.trackName) ?? voiceFromName(clip.name);
  if (fromName != null) return fromName;
  if (clip.notes.isNotEmpty &&
      clip.notes.every((n) => n.pitch < 48)) {
    return SynthVoice.bass;
  }
  return SynthVoice.keys;
}
