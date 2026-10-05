import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/musical_key.dart';
import 'package:daw_project_manager/utils/musical_scale.dart';

MusicalScale s(int root, ScaleType type) => MusicalScale(root, type);

void main() {
  group('scaleFromKey', () {
    test('reads keys the way DAWs and people write them', () {
      expect(scaleFromKey('A minor'), s(9, ScaleType.minor));
      expect(scaleFromKey('C major'), s(0, ScaleType.major));
      expect(scaleFromKey('F#m'), s(6, ScaleType.minor));
      expect(scaleFromKey('Bb'), s(10, ScaleType.major));
      expect(scaleFromKey('Bbm'), s(10, ScaleType.minor));
      expect(scaleFromKey('bm'), s(11, ScaleType.minor));
      expect(scaleFromKey('G# Minor'), s(8, ScaleType.minor));
      expect(scaleFromKey('Eb Major'), s(3, ScaleType.major));
      expect(scaleFromKey('E♭ major'), s(3, ScaleType.major));
    });

    test('reads modes and other scales', () {
      expect(scaleFromKey('C# Dorian'), s(1, ScaleType.dorian));
      expect(scaleFromKey('E Phrygian'), s(4, ScaleType.phrygian));
      expect(scaleFromKey('F Lydian'), s(5, ScaleType.lydian));
      expect(scaleFromKey('G Mixolydian'), s(7, ScaleType.mixolydian));
      expect(scaleFromKey('B Locrian'), s(11, ScaleType.locrian));
      expect(scaleFromKey('A Aeolian'), s(9, ScaleType.minor));
      expect(scaleFromKey('A Harmonic Minor'), s(9, ScaleType.harmonicMinor));
      expect(scaleFromKey('A melodic minor'), s(9, ScaleType.melodicMinor));
      expect(scaleFromKey('E minor pentatonic'), s(4, ScaleType.minorPentatonic));
      expect(scaleFromKey('C Major Pentatonic'), s(0, ScaleType.majorPentatonic));
      expect(scaleFromKey('A blues'), s(9, ScaleType.blues),
          reason: 'the b starts "blues", it is not a flat');
      expect(scaleFromKey('Bb blues'), s(10, ScaleType.blues));
    });

    test('reads Camelot codes', () {
      expect(scaleFromKey('8A'), s(9, ScaleType.minor));
      expect(scaleFromKey('8B'), s(0, ScaleType.major));
      expect(scaleFromKey('9A'), s(4, ScaleType.minor));
      expect(scaleFromKey('1B'), s(11, ScaleType.major));
      expect(scaleFromKey('1A'), s(8, ScaleType.minor));
    });

    test('anything else is no scale', () {
      expect(scaleFromKey(null), isNull);
      expect(scaleFromKey(''), isNull);
      expect(scaleFromKey('Unknown'), isNull);
      expect(scaleFromKey('C whole tone'), isNull);
    });
  });

  group('MusicalScale', () {
    test('contains the scale degrees in every octave', () {
      final aMinor = s(9, ScaleType.minor);
      // A B C D E F G
      for (final p in [57, 59, 60, 62, 64, 65, 67, 69, 81]) {
        expect(aMinor.contains(p), isTrue, reason: '$p');
      }
      for (final p in [58, 61, 63, 66, 68]) {
        expect(aMinor.contains(p), isFalse, reason: '$p');
      }
      expect(aMinor.isRoot(57), isTrue);
      expect(aMinor.isRoot(69), isTrue);
      expect(aMinor.isRoot(60), isFalse);
    });

    test('keyText reads back as the same scale, and as a key signature', () {
      for (final type in ScaleType.values) {
        for (var root = 0; root < 12; root++) {
          final scale = s(root, type);
          expect(scaleFromKey(scale.keyText), scale, reason: scale.keyText);
        }
      }
      expect(s(9, ScaleType.minor).keyText, 'A minor');
      expect(keySignatureOf(s(9, ScaleType.minor).keyText),
          const MidiKeySignature(0, minor: true));
      expect(keySignatureOf(s(1, ScaleType.dorian).keyText),
          const MidiKeySignature(5, minor: false));
    });

    test('every scale has its root and stays inside the octave', () {
      for (final type in ScaleType.values) {
        expect(type.intervals.first, 0);
        expect(type.intervals.every((i) => i >= 0 && i < 12), isTrue);
      }
    });
  });
}
