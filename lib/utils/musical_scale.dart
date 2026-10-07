/// The scales the piano roll can highlight, each as semitones above its
/// root.
enum ScaleType {
  major([0, 2, 4, 5, 7, 9, 11]),
  minor([0, 2, 3, 5, 7, 8, 10]),
  harmonicMinor([0, 2, 3, 5, 7, 8, 11]),
  melodicMinor([0, 2, 3, 5, 7, 9, 11]),
  dorian([0, 2, 3, 5, 7, 9, 10]),
  phrygian([0, 1, 3, 5, 7, 8, 10]),
  lydian([0, 2, 4, 6, 7, 9, 11]),
  mixolydian([0, 2, 4, 5, 7, 9, 10]),
  locrian([0, 1, 3, 5, 6, 8, 10]),
  majorPentatonic([0, 2, 4, 7, 9]),
  minorPentatonic([0, 3, 5, 7, 10]),
  blues([0, 3, 5, 6, 7, 10]);

  const ScaleType(this.intervals);

  final List<int> intervals;

  /// How the type is written after the root in a key — the words
  /// [scaleFromKey] (and `keySignatureOf`) read back.
  String get keyText => switch (this) {
        major => 'major',
        minor => 'minor',
        harmonicMinor => 'harmonic minor',
        melodicMinor => 'melodic minor',
        dorian => 'Dorian',
        phrygian => 'Phrygian',
        lydian => 'Lydian',
        mixolydian => 'Mixolydian',
        locrian => 'Locrian',
        majorPentatonic => 'major pentatonic',
        minorPentatonic => 'minor pentatonic',
        blues => 'blues',
      };
}

/// The root names a scale is shown with: sharps or flats, whichever is the
/// usual spelling for a key on that note.
const scaleRootNames = [
  'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
];

/// A scale on a root: [root] is a pitch class, 0 = C … 11 = B.
class MusicalScale {
  const MusicalScale(this.root, this.type) : assert(root >= 0 && root < 12);

  final int root;
  final ScaleType type;

  /// Whether MIDI note [pitch] is in the scale, in any octave.
  bool contains(int pitch) => type.intervals.contains((pitch - root) % 12);

  /// Whether [pitch] is the scale's root, in any octave.
  bool isRoot(int pitch) => (pitch - root) % 12 == 0;

  /// The scale written as a key — "A minor", "C# Dorian", "Eb major
  /// pentatonic" — which reads back as the same scale, and as a key
  /// signature where it has one. What a clip saved from the piano roll
  /// keeps as its key.
  String get keyText => '${scaleRootNames[root]} ${type.keyText}';

  @override
  bool operator ==(Object other) =>
      other is MusicalScale && other.root == root && other.type == type;

  @override
  int get hashCode => Object.hash(root, type);

  @override
  String toString() => 'MusicalScale($keyText)';
}

const _letterPitch = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

final _camelot = RegExp(r'^(1[0-2]|[1-9])\s*([AaBb])$');
final _named = RegExp(r'^([A-Ga-g])\s*(#|♯|b|♭|-?sharp|-?flat)?\s*(.*)$');

/// Reads a project's key — "A minor", "F#m", "Bb", "C# Dorian", "A Harmonic
/// Minor", "E minor pentatonic", Camelot "8A" — as a scale to highlight.
/// Null when it doesn't read as one of [ScaleType]'s scales.
MusicalScale? scaleFromKey(String? key) {
  final text = key?.trim() ?? '';
  if (text.isEmpty) return null;

  final camelot = _camelot.firstMatch(text);
  if (camelot != null) {
    // 8B is C major and 8A its relative, A minor; each step adds a fifth.
    final n = int.parse(camelot.group(1)!);
    final major = ((n - 8) * 7) % 12;
    return camelot.group(2)!.toUpperCase() == 'A'
        ? MusicalScale((major + 9) % 12, ScaleType.minor)
        : MusicalScale(major, ScaleType.major);
  }

  final named = _named.firstMatch(text);
  if (named == null) return null;
  final natural = _letterPitch[named.group(1)!.toUpperCase()]!;
  final accidental = named.group(2) ?? '';
  final lower = accidental.toLowerCase();
  final shift = accidental.isEmpty
      ? 0
      : (lower.contains('#') || lower.contains('♯') || lower.contains('sharp'))
          ? 1
          : -1;

  final type = _typeOf(named.group(3)!.trim());
  if (type != null) return MusicalScale((natural + shift) % 12, type);
  // "A blues": the b was the start of the scale's name, not a flat.
  if (accidental == 'b') {
    final asWord = _typeOf('b${named.group(3)!}'.trim());
    if (asWord != null) return MusicalScale(natural, asWord);
  }
  return null;
}

ScaleType? _typeOf(String rest) {
  final lower = rest.toLowerCase();
  if (rest.isEmpty || rest == 'M') return ScaleType.major;
  if (lower.contains('pentatonic')) {
    return lower.contains('min') || lower.startsWith('m ')
        ? ScaleType.minorPentatonic
        : ScaleType.majorPentatonic;
  }
  if (lower.contains('blues')) return ScaleType.blues;
  if (lower.contains('harmonic')) return ScaleType.harmonicMinor;
  if (lower.contains('melodic')) return ScaleType.melodicMinor;
  for (final (word, type) in const [
    ('ionian', ScaleType.major),
    ('aeolian', ScaleType.minor),
    ('dorian', ScaleType.dorian),
    ('phrygian', ScaleType.phrygian),
    ('lydian', ScaleType.lydian),
    ('mixolydian', ScaleType.mixolydian),
    ('locrian', ScaleType.locrian),
  ]) {
    if (lower == word) return type;
  }
  if (lower.startsWith('maj') || lower.contains('major')) return ScaleType.major;
  if (lower == 'm' || lower.startsWith('min') || lower.contains('minor')) {
    return ScaleType.minor;
  }
  return null;
}
