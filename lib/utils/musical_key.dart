/// A key as a Standard MIDI File's key-signature event holds it: sharps
/// (positive) or flats (negative), −7…7, and major or minor.
class MidiKeySignature {
  const MidiKeySignature(this.sharps, {required this.minor});

  final int sharps;
  final bool minor;

  @override
  bool operator ==(Object other) =>
      other is MidiKeySignature && other.sharps == sharps && other.minor == minor;

  @override
  int get hashCode => Object.hash(sharps, minor);

  @override
  String toString() => 'MidiKeySignature($sharps, ${minor ? 'minor' : 'major'})';
}

/// Fifths from C for each natural note: F −1, C 0, G 1 … B 5.
const _fifthsOf = {'F': -1, 'C': 0, 'G': 1, 'D': 2, 'A': 3, 'E': 4, 'B': 5};

/// How far each mode's signature sits from the major key on the same tonic,
/// in fifths: D dorian has C major's signature, two fifths down from D's.
const _modeShift = {
  'ionian': 0,
  'dorian': -2,
  'phrygian': -4,
  'lydian': 1,
  'mixolydian': -1,
  'aeolian': -3,
  'locrian': -5,
};

final _camelot = RegExp(r'^(1[0-2]|[1-9])\s*([AaBb])$');
final _named = RegExp(r'^([A-Ga-g])\s*(#|♯|b|♭|-?sharp|-?flat)?\s*(.*)$');

/// Reads a project's key as people and DAWs write it — "A minor", "F#m",
/// "Bb", "Eb Major", "C# Dorian", "Am", Camelot "8A" — into a key
/// signature. Null when it isn't a key this can place: empty, a scale with
/// no major/minor reading ("C Blues"), or not a note at all.
///
/// Modes take their parent major's signature and count as major, except
/// aeolian (natural minor); a MIDI key signature knows only major and minor.
MidiKeySignature? keySignatureOf(String? key) {
  final text = key?.trim() ?? '';
  if (text.isEmpty) return null;

  final camelot = _camelot.firstMatch(text);
  if (camelot != null) {
    // 8A = A minor and 8B = C major, both no sharps; each step clockwise
    // adds a sharp. Kept in −6…5, the spelling DJ software shows.
    final n = int.parse(camelot.group(1)!);
    final sharps = ((n - 8 + 6) % 12) - 6;
    return MidiKeySignature(sharps,
        minor: camelot.group(2)!.toUpperCase() == 'A');
  }

  final named = _named.firstMatch(text);
  if (named == null) return null;
  final accidental = (named.group(2) ?? '').toLowerCase();
  var fifths = _fifthsOf[named.group(1)!.toUpperCase()]!;
  if (accidental.contains('#') ||
      accidental.contains('♯') ||
      accidental.contains('sharp')) {
    fifths += 7;
  } else if (accidental.isNotEmpty) {
    fifths -= 7;
  }

  final rest = named.group(3)!.trim();
  final lower = rest.toLowerCase();
  bool minor;
  if (rest.isEmpty ||
      rest == 'M' ||
      lower.startsWith('maj') ||
      lower == 'ionian') {
    minor = false;
  } else if (lower == 'm' ||
      lower.startsWith('min') ||
      lower == 'aeolian' ||
      lower.contains('minor')) {
    minor = true;
  } else if (_modeShift.containsKey(lower)) {
    return MidiKeySignature(_wrap(fifths + _modeShift[lower]!), minor: false);
  } else if (lower.contains('major')) {
    minor = false;
  } else {
    return null;
  }
  // A minor key's signature is its relative major's, three fifths down.
  return MidiKeySignature(_wrap(minor ? fifths - 3 : fifths), minor: minor);
}

/// Spells a signature past 7 accidentals the other way round: G# major
/// (8 sharps) is written as A♭ major (4 flats).
int _wrap(int fifths) {
  var f = fifths;
  while (f > 7) {
    f -= 12;
  }
  while (f < -7) {
    f += 12;
  }
  return f;
}
