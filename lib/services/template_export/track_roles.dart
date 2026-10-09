/// The role a track plays ("kick", "bass"…), whatever the user called it.
///
/// "Kick 1", "KICK" and "kick_main" are the same thing to a template: the
/// name is lower-cased, accents and trailing numbers dropped, separators
/// collapsed, and the result looked up in an alias table.
const String kUnknownRole = 'unknown';

/// Name → role, keyed by [roleKey]. A role's own name always matches itself.
const Map<String, String> kDefaultRoleAliases = {
  // Drums
  'kick': 'kick', 'kick drum': 'kick', 'bd': 'kick', 'bassdrum': 'kick',
  'bass drum': 'kick', 'bumbo': 'kick',
  'snare': 'snare', 'sd': 'snare', 'caixa': 'snare',
  'clap': 'clap', 'claps': 'clap', 'palma': 'clap', 'palmas': 'clap',
  'hat': 'hats', 'hats': 'hats', 'hihat': 'hats', 'hi hat': 'hats',
  'hihats': 'hats', 'hh': 'hats', 'chimbal': 'hats',
  'perc': 'percs', 'percs': 'percs', 'percussion': 'percs',
  'percussao': 'percs',
  'tom': 'toms', 'toms': 'toms',
  'cymbal': 'cymbals', 'cymbals': 'cymbals', 'overhead': 'cymbals',
  'overheads': 'cymbals', 'oh': 'cymbals',
  'drums': 'drums', 'drum': 'drums', 'bateria': 'drums',
  'drums bus': 'drums_bus', 'drum bus': 'drums_bus',
  // Low end
  'bass': 'bass', 'baixo': 'bass', 'sub': 'bass', 'sub bass': 'bass',
  '808': 'bass', 'bass guitar': 'bass',
  'bass bus': 'bass_bus',
  // Harmony and melody
  'lead': 'lead', 'leads': 'lead', 'melody': 'lead', 'melodia': 'lead',
  'pad': 'pad', 'pads': 'pad',
  'keys': 'keys', 'piano': 'keys', 'rhodes': 'keys', 'teclado': 'keys',
  'organ': 'keys', 'orgao': 'keys',
  'synth': 'synth', 'synths': 'synth', 'sinte': 'synth',
  'arp': 'arp', 'arps': 'arp', 'arpeggio': 'arp',
  'chords': 'chords', 'chord': 'chords', 'acordes': 'chords',
  'pluck': 'pluck', 'plucks': 'pluck',
  'guitar': 'guitar', 'guitars': 'guitar', 'gtr': 'guitar',
  'guitarra': 'guitar', 'violao': 'guitar',
  'strings': 'strings', 'string': 'strings', 'cordas': 'strings',
  'brass': 'brass', 'metais': 'brass',
  // Voices
  'vocal': 'vocals', 'vocals': 'vocals', 'vox': 'vocals', 'voz': 'vocals',
  'lead vocal': 'lead_vocal', 'lead vox': 'lead_vocal',
  'backing vocals': 'backing_vocals', 'backing': 'backing_vocals',
  'bv': 'backing_vocals', 'bvs': 'backing_vocals', 'harmony': 'backing_vocals',
  'harmonies': 'backing_vocals', 'coro': 'backing_vocals',
  'vocal bus': 'vocals_bus', 'vocals bus': 'vocals_bus',
  // Effects and returns
  'fx': 'fx', 'sfx': 'fx', 'effects': 'fx', 'efeitos': 'fx',
  'riser': 'fx_riser', 'risers': 'fx_riser', 'fx riser': 'fx_riser',
  'impact': 'fx_impact', 'impacts': 'fx_impact', 'fx impact': 'fx_impact',
  'reverb': 'reverb', 'verb': 'reverb', 'hall': 'reverb', 'room': 'reverb',
  'delay': 'delay', 'echo': 'delay',
  'fx bus': 'fx_bus', 'music bus': 'music_bus', 'master': 'master',
  'mix bus': 'master',
  'stab': 'stabs', 'stabs': 'stabs',
  'sweep': 'sweeps', 'sweeps': 'sweeps', 'sweep up': 'sweeps',
  'sweep down': 'sweeps', 'reverse sweep': 'sweeps',
  'crash': 'crash', 'crashes': 'crash',
  'open hi hat': 'hats', 'closed hi hat': 'hats', 'open hat': 'hats',
  'closed hat': 'hats', 'percussions': 'percs',
  'drum fill': 'drum_fill', 'drumfill': 'drum_fill', 'fill': 'drum_fill',
  'fxs': 'fx',
  // Folders people commonly make
  'sample': 'samples', 'samples': 'samples', 'loops': 'loops', 'loop': 'loops',
  'reference': 'reference', 'ref': 'reference', 'referencia': 'reference',
};

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// Lower case, no accents, separators as single spaces, no trailing numbers.
String roleKey(String name) {
  final buffer = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'[\s#]*\d+$'), '')
      .trim();
}

/// The role of [name], or [kUnknownRole] when nothing matches. [aliases]
/// (keyed by [roleKey]) take precedence over the defaults.
///
/// Names like "DRUMS - Closed Hi Hat 01" are tried as a whole first, then
/// segment by segment, the last first ("Closed Hi Hat" before "DRUMS"): each
/// segment as it stands, then by the longest alias found as whole words
/// inside it (ties go to the later word, where the noun usually is: "Kick
/// Impact" is an impact).
String roleOf(String name, {Map<String, String> aliases = const {}}) {
  String? lookup(String key) => aliases[key] ?? kDefaultRoleAliases[key];

  final whole = roleKey(name);
  if (whole.isEmpty) return kUnknownRole;
  final exact = lookup(whole);
  if (exact != null) return exact;

  final segments = name
      .split(RegExp(r'\s+[-–]\s+'))
      .map(roleKey)
      .where((k) => k.isNotEmpty)
      .toList()
      .reversed
      .toList();
  final candidates = {...kDefaultRoleAliases, ...aliases};
  for (final key in segments) {
    final exactSegment = lookup(key);
    if (exactSegment != null) return exactSegment;
    final words = key.split(' ');
    String? best;
    var bestLength = 0;
    var bestEnd = -1;
    candidates.forEach((alias, role) {
      final parts = alias.split(' ');
      for (var at = 0; at + parts.length <= words.length; at++) {
        var match = true;
        for (var j = 0; j < parts.length; j++) {
          if (words[at + j] != parts[j]) {
            match = false;
            break;
          }
        }
        if (!match) continue;
        final end = at + parts.length;
        if (parts.length > bestLength ||
            (parts.length == bestLength && end > bestEnd)) {
          best = role;
          bestLength = parts.length;
          bestEnd = end;
        }
      }
    });
    if (best != null) return best!;
  }
  return kUnknownRole;
}

/// Whether [name] is itself a known alias ("Kick 1", "HATS") rather than a
/// longer name a role was only found inside ("DRUMS - TOM 01 Right Panned").
bool isCleanAlias(String name, {Map<String, String> aliases = const {}}) {
  final key = roleKey(name);
  return aliases.containsKey(key) || kDefaultRoleAliases.containsKey(key);
}

/// "fx_riser" → "Fx riser": a plain name for a role whose tracks are named
/// too variously to pick one of their spellings.
String roleTitle(String role) {
  final words = role.replaceAll('_', ' ');
  return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
}
