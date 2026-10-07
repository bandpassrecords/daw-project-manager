/// A time signature: [beats] to the bar, each a [unit] note (4: quarter,
/// 8: eighth). What the piano roll draws its bars and beats by, how far a
/// clip grows, and what an exported `.mid` file says.
class TimeSignature {
  const TimeSignature(this.beats, this.unit);

  /// 4/4: what a clip is in until told otherwise.
  static const common = TimeSignature(4, 4);

  final int beats;
  final int unit;

  /// One beat in ticks at [ppq] (ticks per quarter note).
  int beatTicks(int ppq) => (ppq * 4 / unit).round();

  /// One bar in ticks at [ppq].
  int barTicks(int ppq) => beats * beatTicks(ppq);

  /// "3/4", "6/8".
  String get text => '$beats/$unit';

  /// The data of a MIDI time-signature meta event (FF 58): the numerator,
  /// the denominator as a power of two, MIDI clocks per metronome click
  /// (a beat: 24 per quarter note) and 32nd notes per quarter (8).
  List<int> get midiMetaData {
    var power = 0;
    while ((1 << power) < unit) {
      power++;
    }
    return [beats, power, (96 / unit).round(), 8];
  }

  /// Reads [text] back ("3/4", " 6 / 8 "); null for anything that isn't a
  /// time signature a bar can be drawn in.
  static TimeSignature? tryParse(String? text) {
    if (text == null) return null;
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final beats = int.tryParse(parts[0].trim());
    final unit = int.tryParse(parts[1].trim());
    if (beats == null || unit == null) return null;
    if (beats < 1 || beats > 32) return null;
    if (!const {1, 2, 4, 8, 16, 32}.contains(unit)) return null;
    return TimeSignature(beats, unit);
  }

  @override
  bool operator ==(Object other) =>
      other is TimeSignature && other.beats == beats && other.unit == unit;

  @override
  int get hashCode => Object.hash(beats, unit);

  @override
  String toString() => text;
}

/// The time signatures the piano roll offers.
const kTimeSignatureChoices = [
  TimeSignature(2, 4),
  TimeSignature(3, 4),
  TimeSignature(4, 4),
  TimeSignature(5, 4),
  TimeSignature(6, 8),
  TimeSignature(7, 8),
  TimeSignature(9, 8),
  TimeSignature(12, 8),
];
