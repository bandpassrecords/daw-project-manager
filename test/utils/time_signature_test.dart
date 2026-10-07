import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/midi_clip.dart';
import 'package:daw_project_manager/models/midi_collection.dart';
import 'package:daw_project_manager/services/midi/midi_file_writer.dart';
import 'package:daw_project_manager/ui/midi_collection_actions.dart';
import 'package:daw_project_manager/utils/time_signature.dart';

void main() {
  test('beats and bars in ticks', () {
    expect(TimeSignature.common.barTicks(480), 1920);
    expect(const TimeSignature(3, 4).barTicks(480), 1440);
    expect(const TimeSignature(6, 8).beatTicks(480), 240);
    expect(const TimeSignature(6, 8).barTicks(480), 1440);
    expect(const TimeSignature(7, 8).barTicks(960), 3360);
  });

  test('reads back what it writes, and nothing else', () {
    for (final ts in kTimeSignatureChoices) {
      expect(TimeSignature.tryParse(ts.text), ts);
    }
    expect(TimeSignature.tryParse(' 5 / 4 '), const TimeSignature(5, 4));
    for (final bad in [null, '', '4', '4/3', '0/4', 'x/4', '4/4/4']) {
      expect(TimeSignature.tryParse(bad), isNull, reason: '$bad');
    }
  });

  test('the MIDI meta event: numerator, power of two, clocks per beat', () {
    expect(TimeSignature.common.midiMetaData, [4, 2, 24, 8]);
    expect(const TimeSignature(3, 4).midiMetaData, [3, 2, 24, 8]);
    expect(const TimeSignature(6, 8).midiMetaData, [6, 3, 12, 8]);
  });

  test('an exported .mid says its time signature', () {
    const clip = MidiClip(
      name: 'Waltz',
      ppq: 480,
      lengthTicks: 1440,
      notes: [MidiNote(startTick: 0, lengthTicks: 480, pitch: 60, velocity: 90)],
    );
    bool says(List<int> bytes, List<int> data) {
      final needle = [0xFF, 0x58, 4, ...data];
      for (var i = 0; i + needle.length <= bytes.length; i++) {
        var all = true;
        for (var j = 0; j < needle.length && all; j++) {
          all = bytes[i + j] == needle[j];
        }
        if (all) return true;
      }
      return false;
    }

    expect(says(const MidiExport(clip).encode(), [4, 2, 24, 8]), isTrue,
        reason: '4/4 unless told otherwise');
    expect(
        says(
            const MidiExport(clip, timeSignature: TimeSignature(3, 4)).encode(),
            [3, 2, 24, 8]),
        isTrue);
  });

  test('a collection item keeps a time signature, and leaves 4/4 unsaid', () {
    const clip = MidiClip(name: 'x', ppq: 480, lengthTicks: 1440, notes: []);
    final waltz = collectionItemFor(clip, timeSignature: const TimeSignature(3, 4));
    expect(waltz.timeSignature, '3/4');
    final back = MidiCollectionItem.tryParse(waltz.toJson())!;
    expect(back.timeSignature, '3/4');
    expect(back.copyWith(voice: 'pad').timeSignature, '3/4');

    final common = collectionItemFor(clip, timeSignature: TimeSignature.common);
    expect(common.timeSignature, isNull);
    expect(common.toJson().containsKey('timeSig'), isFalse);
  });
}
