import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/musical_key.dart';

MidiKeySignature major(int sharps) => MidiKeySignature(sharps, minor: false);
MidiKeySignature minor(int sharps) => MidiKeySignature(sharps, minor: true);

void main() {
  group('keySignatureOf', () {
    test('reads the ways DAWs write keys', () {
      expect(keySignatureOf('C major'), major(0));
      expect(keySignatureOf('A minor'), minor(0));
      expect(keySignatureOf('G# Minor'), minor(5), reason: 'Bitwig spelling');
      expect(keySignatureOf('Eb Major'), major(-3));
      expect(keySignatureOf('F# minor'), minor(3));
    });

    test('reads the ways people type them', () {
      expect(keySignatureOf('Am'), minor(0));
      expect(keySignatureOf('F#m'), minor(3));
      expect(keySignatureOf('bm'), minor(2), reason: 'lower-case B minor');
      expect(keySignatureOf('Bb'), major(-2));
      expect(keySignatureOf('Bbm'), minor(-5));
      expect(keySignatureOf('D'), major(2));
      expect(keySignatureOf('Db maj'), major(-5));
      expect(keySignatureOf('c min'), minor(-3));
      expect(keySignatureOf('E♭ major'), major(-3));
      expect(keySignatureOf('  A minor  '), minor(0));
    });

    test('reads Camelot codes', () {
      expect(keySignatureOf('8A'), minor(0));
      expect(keySignatureOf('8B'), major(0));
      expect(keySignatureOf('9A'), minor(1), reason: 'E minor');
      expect(keySignatureOf('1A'), minor(5), reason: 'G# minor');
      expect(keySignatureOf('2B'), major(-6), reason: 'G♭ / F# major');
      expect(keySignatureOf('12b'), major(4), reason: 'E major');
    });

    test('modes take their parent major\'s signature', () {
      expect(keySignatureOf('D Dorian'), major(0));
      expect(keySignatureOf('C# Dorian'), major(5));
      expect(keySignatureOf('G Mixolydian'), major(0));
      expect(keySignatureOf('F Lydian'), major(0));
      expect(keySignatureOf('E Phrygian'), major(0));
      expect(keySignatureOf('A Aeolian'), minor(0));
    });

    test('scales named minor or major count as such', () {
      expect(keySignatureOf('A Harmonic Minor'), minor(0));
      expect(keySignatureOf('C Major Pentatonic'), major(0));
    });

    test('past seven accidentals it spells the other way round', () {
      expect(keySignatureOf('G# major'), major(-4), reason: 'as A♭ major');
      expect(keySignatureOf('Fb major'), major(4), reason: 'as E major');
    });

    test('keyNameOf names every signature, and reads back the same', () {
      expect(keyNameOf(minor(0)), 'A minor');
      expect(keyNameOf(major(-3)), 'Eb major');
      expect(keyNameOf(minor(3)), 'F# minor');
      for (var s = -7; s <= 7; s++) {
        for (final m in [true, false]) {
          final sig = MidiKeySignature(s, minor: m);
          expect(keySignatureOf(keyNameOf(sig)), sig, reason: '$sig');
        }
      }
    });

    test('anything else is no key', () {
      expect(keySignatureOf(null), isNull);
      expect(keySignatureOf(''), isNull);
      expect(keySignatureOf('C Blues'), isNull);
      expect(keySignatureOf('Unknown'), isNull);
      expect(keySignatureOf('13A'), isNull);
    });
  });
}
