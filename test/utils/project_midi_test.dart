import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_stats.dart';
import 'package:daw_project_manager/utils/project_midi.dart';

import '../helpers/test_factories.dart';

void main() {
  final withMidi = TestFactories.makeProject(id: 'm')
      .copyWith(stats: const ProjectStats(midiClipCount: 3));
  final noMidi = TestFactories.makeProject(id: 'n')
      .copyWith(stats: const ProjectStats(audioTracks: 4, midiClipCount: 0));
  final neverRead = TestFactories.makeProject(id: 'u');

  test('a project holds MIDI when its last read found clips', () {
    expect(projectHasMidi(withMidi, const []), isTrue);
    expect(projectHasMidi(noMidi, const []), isFalse);
    expect(projectHasMidi(neverRead, const []), isFalse,
        reason: 'never read in full: nothing known yet');
  });

  test('a stack holds MIDI when one of its versions does', () {
    final stack = TestFactories.makeProject(id: 's', isVirtual: true);
    final v1 = noMidi.copyWith(stackId: 's');
    final v2 = withMidi.copyWith(stackId: 's');
    expect(projectHasMidi(stack, [stack, v1]), isFalse);
    expect(projectHasMidi(stack, [stack, v1, v2]), isTrue);
    expect(projectHasMidi(stack, [withMidi]), isFalse,
        reason: 'a project outside the stack does not count');
  });
}
